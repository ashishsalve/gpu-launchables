#!/bin/bash
# Nemotron Omni Browser Agent: NVIDIA Nemotron 3 Nano Omni, served by vLLM on
# this GPU, drives a headed Chromium through Playwright MCP inside an NVIDIA
# OpenShell sandbox with an egress allowlist. One Secure Link (port 7860)
# serves the chat UI and a view-only live desktop; every other service listens
# on localhost only.
#
# Launch parameters (read from this script's environment):
#   MODEL           - model served by vLLM (one option).
#   ALLOWED_DOMAINS - comma-separated host names the browser may reach (max 20,
#                     exact names, no wildcards).
#   MAX_STEPS       - browser steps allowed per task: 10, 25 or 50.
#   HF_TOKEN        - optional Hugging Face read token, no default. Stored only
#                     in a mode 600 file and never printed.
#
# The script stops before installing anything while a pinned checksum or
# image digest below is not a full sha256 value.
set -euo pipefail

MODEL="${MODEL:-nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8}"
ALLOWED_DOMAINS="${ALLOWED_DOMAINS:-en.wikipedia.org,huggingface.co,docs.nvidia.com}"
MAX_STEPS="${MAX_STEPS:-25}"
HF_TOKEN="${HF_TOKEN:-}"

# Pins (see README "Current versions").
MODEL_REVISION="0acd4b1c237eab45d3977b1b46631919e9a75774"
OPENSHELL_VERSION="v0.1.9"
OPENSHELL_INSTALL_SHA256="5d3c758fe1860625cd28b0791865b25e25912acacdc99c8ce1c6071a95ef360b"
# Sandbox and UI image digests, build dev-sha-215eaca, built 2026-11-19.
SANDBOX_DIGEST="444319e3085ca64bb6f8a0b14a0779a609068980f233d0b8f7ee8fd153c4750e"
UI_DIGEST="54d1eb761897073dd571c6d283e09ebd00461ab691b8075a42640549e8cdc712"
SANDBOX_IMAGE="ghcr.io/ashishsalve/nemotron-omni-browser-agent-sandbox:dev-sha-215eaca@sha256:444319e3085ca64bb6f8a0b14a0779a609068980f233d0b8f7ee8fd153c4750e"

for pin in "$OPENSHELL_INSTALL_SHA256" "$SANDBOX_DIGEST" "$UI_DIGEST"; do
  if ! [[ "$pin" =~ ^[0-9a-f]{64}$ ]]; then
    echo "A pinned checksum or image digest is not resolved; refusing to install" >&2
    exit 1
  fi
done

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this setup script as the instance's default user, not root" >&2
  exit 1
fi

case "$MODEL" in
  nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8) ;;
  *) echo "Unsupported MODEL: $MODEL" >&2; exit 1 ;;
esac
case "$MAX_STEPS" in
  10|25|50) ;;
  *) echo "MAX_STEPS must be 10, 25 or 50" >&2; exit 1 ;;
esac

# Domain list: lower case, exact host names, at most 20.
DOMAINS=()
IFS=',' read -r -a RAW_DOMAINS <<<"$ALLOWED_DOMAINS"
for d in "${RAW_DOMAINS[@]}"; do
  d="${d//[[:space:]]/}"
  d="${d,,}"
  [ -z "$d" ] && continue
  if ! [[ "$d" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$ ]]; then
    echo "ALLOWED_DOMAINS entry is not an exact host name: $d" >&2
    exit 1
  fi
  DOMAINS+=("$d")
done
if [ "${#DOMAINS[@]}" -eq 0 ] || [ "${#DOMAINS[@]}" -gt 20 ]; then
  echo "ALLOWED_DOMAINS must list 1 to 20 host names" >&2
  exit 1
fi
DOMAIN_CSV="$(IFS=','; echo "${DOMAINS[*]}")"

# Preconditions. The base image provides the driver, Docker and the NVIDIA
# Container Toolkit; this script never reinstalls them.
command -v nvidia-smi >/dev/null || { echo "nvidia-smi not found" >&2; exit 1; }
command -v docker >/dev/null || { echo "docker not found" >&2; exit 1; }

WS="$HOME/workspace"
APP="$WS/browser-agent"
STATE="$APP/.state"
UID_NUM="$(id -u)"
GID_NUM="$(id -g)"
# HF cache placement: model and download temp files on one filesystem. Root
# under 80 GB free -> instance store (emptied by a stop) if over 80 GB free.
gb_free() { df -P -BG "$1" 2>/dev/null | awk 'NR == 2 { sub(/G$/, "", $4); print $4 + 0 }'; }
ROOT_FREE="$(gb_free "$HOME")"; ROOT_FREE="${ROOT_FREE:-0}"
ALT=""; ALT_FREE=0
for m in /opt/dlami/nvme $(findmnt -rn -o SOURCE,TARGET 2>/dev/null | awk '$1 ~ /^\/dev\/nvme[0-9]+n1$/ && $2 != "/" { print $2 }'); do
  mountpoint -q "$m" 2>/dev/null || continue
  f="$(gb_free "$m")"
  if [ "${f:-0}" -gt "$ALT_FREE" ]; then ALT="$m"; ALT_FREE="$f"; fi
done
HF_MOUNT=""
PREV="$(cat "$STATE/hf-dir" 2>/dev/null || true)"
if [ -n "$PREV" ]; then
  HFC="$PREV"; [ "$HFC" = "$WS/huggingface" ] || HF_MOUNT="${HFC%/browser-agent-hf}"
elif [ "$ROOT_FREE" -lt 80 ] && [ -n "$ALT" ] && [ "$ALT_FREE" -gt 80 ]; then HF_MOUNT="$ALT"
elif [ "$ROOT_FREE" -ge 45 ]; then :
elif [ -n "$ALT" ] && [ "$ALT_FREE" -ge 45 ]; then HF_MOUNT="$ALT"
else
  echo "Not enough disk: the model cache needs >= 45 GB free; root has ${ROOT_FREE} GB, instance store ${ALT:-none} has ${ALT_FREE} GB. Redeploy with a larger disk." >&2
  exit 1
fi
if [ -n "$HF_MOUNT" ]; then
  HFC="$HF_MOUNT/browser-agent-hf"
  sudo install -d -o "$USER" -g "$(id -gn)" "$HFC" "$HFC/hub" "$HFC/tmp"
  [ -d "$WS/huggingface" ] && [ ! -L "$WS/huggingface" ] && rmdir "$WS/huggingface" 2>/dev/null || true
  mkdir -p "$WS"
  [ -d "$WS/huggingface" ] || ln -sfn "$HFC" "$WS/huggingface"
else
  HFC="$WS/huggingface"
  mkdir -p "$HFC/hub" "$HFC/tmp"
fi
mkdir -p "$STATE"
echo "$HFC" > "$STATE/hf-dir"
echo "HF cache: $HFC (root free ${ROOT_FREE} GB; instance store ${ALT:-none} ${ALT_FREE} GB)"
# end HF cache placement
export XDG_RUNTIME_DIR="/run/user/$UID_NUM"
mkdir -p "$APP/data/output" "$APP/data/logs" "$STATE" "$HOME/.config/systemd/user"
touch "$APP/data/logs/denials.log"

# Settings files, mode 600. The model API needs no key; it listens on localhost.
umask 077
cat > "$APP/agent.env" <<EOF
OPENAI_BASE_URL=http://127.0.0.1:8000/v1
OPENAI_API_KEY=none
MODEL_NAME=nemotron-omni
MCP_URL=http://127.0.0.1:8931/mcp
MAX_STEPS=${MAX_STEPS}
OUTPUT_DIR=/data/output
DENIAL_LOG=/data/logs/denials.log
ALLOWED_DOMAINS=${DOMAIN_CSV}
UI_PORT=7861
EOF
: > "$APP/hf.env"
if [ -n "$HF_TOKEN" ]; then
  cat > "$APP/hf.env" <<EOF
HF_TOKEN=${HF_TOKEN}
EOF
fi
chmod 600 "$APP/agent.env" "$APP/hf.env"
umask 022

# OpenShell sandbox policy: read-only system, writable /tmp and /workspace,
# outbound HTTPS only to the listed hosts, only for the bundled Chromium.
# tls: skip passes TLS through (the browser rejects the gateway's own
# certificate); the host allowlist still applies to every connection.
{
  echo "version: 1"
  echo "filesystem_policy:"
  echo "  read_only: [/usr, /lib, /etc, /opt/agent]"
  echo "  read_write: [/tmp, /workspace]"
  echo "network_policies:"
  echo "  browse_allowlist:"
  echo "    endpoints:"
  for d in "${DOMAINS[@]}"; do
    echo "      - host: $d"
    echo "        port: 443"
    echo "        tls: skip"
  done
  echo "    binaries:"
  echo "      - path: /opt/agent/chromium/chrome"
} > "$APP/policy.yaml"

# Reverse proxy for the Secure Link: chat UI on /, live desktop on /vnc/.
cat > "$APP/nginx.conf" <<'EOF'
map $http_upgrade $connection_upgrade {
  default upgrade;
  '' close;
}
server {
  listen 7860;
  client_max_body_size 1m;
  location /vnc/ {
    proxy_pass http://127.0.0.1:6080/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_read_timeout 3600s;
  }
  location / {
    proxy_pass http://127.0.0.1:7861;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_buffering off;
    proxy_read_timeout 900s;
  }
}
EOF

# OpenShell CLI and gateway: the release .deb (built from commit
# ce58cf8e9b953281352d98a637e41616295b1318), checksum verified before install.
if ! command -v openshell >/dev/null 2>&1 || ! openshell --version 2>/dev/null | grep -qF "${OPENSHELL_VERSION#v}"; then
  os_tmp="$(mktemp -d)"
  curl -fsSL --retry 3 -o "$os_tmp/openshell.deb" \
    "https://github.com/NVIDIA/OpenShell/releases/download/${OPENSHELL_VERSION}/openshell_${OPENSHELL_VERSION#v}-1_amd64.deb"
  printf '%s  %s\n' "$OPENSHELL_INSTALL_SHA256" "$os_tmp/openshell.deb" | sha256sum -c --quiet - || {
    echo "openshell: package checksum mismatch" >&2
    rm -rf "$os_tmp"
    exit 1
  }
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$os_tmp/openshell.deb"
  rm -rf "$os_tmp"
fi
openshell --version
OPENSHELL_BIN="$(command -v openshell)"
sudo usermod -aG docker "$USER"
sudo loginctl enable-linger "$USER"
mkdir -p "$HOME/.config/systemd/user/openshell-gateway.service.d"
cat > "$HOME/.config/systemd/user/openshell-gateway.service.d/telemetry.conf" <<EOF
[Service]
Environment=OPENSHELL_TELEMETRY_ENABLED=false
EOF

# User units: port forwards out of the sandbox and the policy-denial log.
cat > "$HOME/.config/systemd/user/browser-agent-forward@.service" <<EOF
[Unit]
Description=OpenShell forward of sandbox port %i to localhost
After=openshell-gateway.service

[Service]
Environment=OPENSHELL_TELEMETRY_ENABLED=false
ExecStart=$OPENSHELL_BIN forward start %i browser-agent
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
cat > "$HOME/.config/systemd/user/browser-agent-denials.service" <<EOF
[Unit]
Description=OpenShell sandbox log for the browser agent step log
After=openshell-gateway.service

[Service]
ExecStart=/bin/bash -c 'exec $OPENSHELL_BIN logs browser-agent --source sandbox --tail >> $APP/data/logs/denials.log 2>&1'
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Boot script: idempotent, run by systemd at every boot and every 5 minutes.
cat > "$APP/up.sh" <<EOF
#!/bin/bash
set -euo pipefail
export XDG_RUNTIME_DIR=/run/user/$UID_NUM
for _ in \$(seq 1 90); do
  if docker info >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then break; fi
  sleep 10
done
docker info >/dev/null
# Keep the sandbox log under 5 MiB: truncate in place to its last 1 MiB.
LOG=$APP/data/logs/denials.log
if [ "\$(stat -c %s \$LOG 2>/dev/null || echo 0)" -gt 5242880 ]; then
  tail -c 1048576 \$LOG > \$LOG.tmp
  cat \$LOG.tmp > \$LOG
  rm -f \$LOG.tmp
fi
running() { [ "\$(docker inspect -f '{{.State.Running}}' "\$1" 2>/dev/null || true)" = "true" ]; }
exists() { docker inspect "\$1" >/dev/null 2>&1; }
if [ -n "$HF_MOUNT" ]; then
  for _ in \$(seq 1 30); do mountpoint -q $HF_MOUNT && break; sleep 10; done
  mountpoint -q $HF_MOUNT || { echo "Model cache mount $HF_MOUNT is not mounted" >&2; exit 1; }
  [ -d $HFC/tmp ] || sudo install -d -o $UID_NUM -g $GID_NUM $HFC $HFC/hub $HFC/tmp
fi
if ! exists vllm; then
  docker run -d --gpus all --name vllm --restart unless-stopped --ipc host -p 127.0.0.1:8000:8000 -v $HFC:/root/.cache/huggingface -e HF_HOME=/root/.cache/huggingface -e HF_HUB_CACHE=/root/.cache/huggingface/hub -e TMPDIR=/root/.cache/huggingface/tmp --env-file $APP/hf.env vllm/vllm-openai:v0.33.0@sha256:d825baf9ce4b1b6bfc5ecc7b79880c7e6748c65a72d697ce3d47607aafa84c6e $MODEL --revision $MODEL_REVISION --served-model-name nemotron-omni --host 0.0.0.0 --port 8000 --trust-remote-code --enable-auto-tool-choice --tool-call-parser qwen3_coder --reasoning-parser nemotron_v3 --max-model-len 65536 --max-num-seqs 4 --gpu-memory-utilization 0.90 --limit-mm-per-prompt '{"image": 2}'
elif ! running vllm; then docker start vllm; fi
for _ in \$(seq 1 30); do
  systemctl --user show-environment >/dev/null 2>&1 && break
  sleep 1
done
systemctl --user daemon-reload
systemctl --user start openshell-gateway.service
# Wait for the gateway listener, then register it with the CLI (the .deb
# install does not) and make it the active gateway. Safe to repeat.
gw_up=0
for _ in \$(seq 1 60); do
  if (exec 3<>/dev/tcp/127.0.0.1/17670) 2>/dev/null; then gw_up=1; break; fi
  sleep 2
done
if [ "\$gw_up" -ne 1 ]; then
  echo "OpenShell gateway is not listening on 127.0.0.1:17670 after 120 s" >&2
  exit 1
fi
if ! $OPENSHELL_BIN gateway select openshell >/dev/null 2>&1; then
  $OPENSHELL_BIN gateway add https://127.0.0.1:17670 --local --name openshell
  $OPENSHELL_BIN gateway select openshell
fi
echo "gateway select ok"
$OPENSHELL_BIN gateway info >/dev/null || { echo "No active OpenShell gateway" >&2; exit 1; }
# Sandbox: create if absent; delete and re-create if in phase Error, at most
# 3 times in a row (count in .state, reset by any other phase); start only
# from a startable phase. Failures stop this script (the timer retries).
sb_create() { $OPENSHELL_BIN sandbox create --name browser-agent --from $SANDBOX_IMAGE --policy $APP/policy.yaml --detach -- /opt/agent/start-desktop.sh; }
ERRS=$STATE/sandbox-errors
sb_list="\$($OPENSHELL_BIN sandbox list)"
phase="\$(awk '\$1 == "browser-agent" { print \$NF }' <<<"\$sb_list")"
n=0
if [ "\$phase" = Error ]; then
  n="\$(cat \$ERRS 2>/dev/null || true)"
  case "\$n" in ''|*[!0-9]*) n=0 ;; esac
  n=\$((n + 1))
  echo "\$n" > \$ERRS
else
  rm -f \$ERRS
fi
case "\$phase" in
  "") sb_create ;;
  Error)
    if [ "\$n" -gt 3 ]; then
      echo "Sandbox browser-agent keeps failing (phase Error \$n times in a row); see journalctl -u browser-agent.service; not re-creating"
    else
      echo "Sandbox browser-agent is in phase Error; deleting and re-creating it (\$n of 3)"
      $OPENSHELL_BIN sandbox delete browser-agent
      sb_create
    fi ;;
  Stopped|Suspended|Completed) $OPENSHELL_BIN sandbox start browser-agent ;;
  *) echo "Sandbox browser-agent phase: \$phase" ;;
esac
systemctl --user start browser-agent-forward@8931.service browser-agent-forward@6080.service browser-agent-denials.service
# The UI runs as this user, who owns data/output (screenshots per task).
if ! exists agent-ui; then
  docker run -d --name agent-ui --restart unless-stopped --network host --user $UID_NUM:$UID_NUM --env-file $APP/agent.env -v $APP/data:/data ghcr.io/ashishsalve/nemotron-omni-browser-agent-ui:dev-sha-215eaca@sha256:54d1eb761897073dd571c6d283e09ebd00461ab691b8075a42640549e8cdc712
elif ! running agent-ui; then docker start agent-ui; fi
if ! exists agent-proxy; then
  docker run -d --name agent-proxy --restart unless-stopped --network host -v $APP/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx:1.31.9-alpine@sha256:0713660ff64e819a478be0d69ae314e52d21623c93672edd9f381a6e66fd95ff
elif ! running agent-proxy; then docker start agent-proxy; fi
EOF
chmod 755 "$APP/up.sh"

# System units: no dependency on docker or GPU units (up.sh waits for both).
sudo tee /etc/systemd/system/browser-agent.service >/dev/null <<EOF
[Unit]
Description=Nemotron Omni Browser Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
Environment=HOME=$HOME
ExecStart=$APP/up.sh
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
sudo tee /etc/systemd/system/browser-agent-recover.timer >/dev/null <<EOF
[Unit]
Description=Re-check the browser agent every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=browser-agent.service

[Install]
WantedBy=timers.target
EOF
sudo systemctl daemon-reload
# User manager: start it, never restart it (a restart can race the old
# cgroup teardown). Only if it runs without the docker group, stop it, wait
# for its cgroup to go, then start it again.
UM="user@$UID_NUM.service"
UM_CG="/sys/fs/cgroup/user.slice/user-$UID_NUM.slice/$UM"
DOCKER_GID="$(getent group docker | cut -d: -f3)"
um_pid="$(systemctl show -p MainPID --value "$UM" 2>/dev/null || echo 0)"
if [ "${um_pid:-0}" -gt 0 ] && [ -n "$DOCKER_GID" ] &&
  ! grep -Eq "^Groups:(.*[[:space:]])?${DOCKER_GID}([[:space:]]|\$)" "/proc/$um_pid/status"; then
  sudo systemctl stop "$UM"
  for _ in $(seq 1 30); do
    [ -d "$UM_CG" ] || break
    sleep 1
  done
fi
um_ok=0
for i in $(seq 1 5); do
  if sudo systemctl start "$UM"; then um_ok=1; break; fi
  sleep "$((i * 2))"
done
if [ "$um_ok" -ne 1 ]; then
  echo "Could not start $UM; see: journalctl -u $UM" >&2
  exit 1
fi
um_ok=0
for _ in $(seq 1 30); do
  if systemctl --user show-environment >/dev/null 2>&1; then um_ok=1; break; fi
  sleep 1
done
if [ "$um_ok" -ne 1 ]; then
  echo "The systemd user manager did not respond within 30 s" >&2
  exit 1
fi
sudo systemctl enable browser-agent.service browser-agent-recover.timer
sudo systemctl start browser-agent.service browser-agent-recover.timer

# Health check: the UI answers through the proxy. The model keeps loading in
# the background; the page header shows when it is ready.
for _ in $(seq 1 120); do
  if curl -fsS --max-time 5 http://localhost:7860/healthz 2>/dev/null | grep -q '"ui":"ok"'; then
    echo "Browser agent UI is up on port 7860; the model may still be loading."
    exit 0
  fi
  sleep 10
done
echo "Browser agent UI did not answer on http://localhost:7860/healthz within 20 minutes" >&2
exit 1
