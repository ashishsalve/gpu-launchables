#!/bin/bash
set -euo pipefail
umask 022

AGENT_HARNESS="${AGENT_HARNESS:-openclaw}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-65536}"
APP=/home/ubuntu/workspace/private-agent
[[ $(id -u) != 0 && $AGENT_HARNESS =~ ^(openclaw|hermes|langchain-deepagents-code)$ && $MAX_MODEL_LEN =~ ^(32768|65536|131072)$ ]]||{ echo "Bad user or parameter" >&2;exit 1;}
command -v nvidia-smi >/dev/null && command -v docker >/dev/null || { echo "Need nvidia-smi, docker" >&2; exit 1; }
mkdir -p "$APP" "$HOME/.local/bin"
chmod 755 "$HOME" "$HOME/.local" "$HOME/.local/bin" "$APP"
(umask 077;printf 'AGENT_HARNESS=%s\nMAX_MODEL_LEN=%s\n' "$AGENT_HARNESS" "$MAX_MODEL_LEN" >"$APP/params.env";touch "$APP/vllm.env")
chmod 600 "$APP/params.env" "$APP/vllm.env"

cat > "$APP/post-recover.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
if [ "${1:-}" = pre ];then
# 11435 guard; proxy restart
for t in iptables $(command -v ip6tables||:);do for r in "! -i lo -j DROP" "-i br-+ -j ACCEPT" "-i docker0 -j ACCEPT";do R="PREROUTING -t raw -p tcp --dport 11435 $r";sudo $t -C $R 2>/dev/null||sudo $t -I $R;done;done
l(){ [ -n "$(ss -Hltn sport = :11435)" ];}
cd ~/.nemoclaw&&[ -s ollama-proxy-token ]||{ echo "proxy: skip";exit;}
l||(export OLLAMA_PROXY_TOKEN=$(<ollama-proxy-token);[ ! -s ollama-backend ]||export OLLAMA_BACKEND_URL=$(<ollama-backend);setsid node --no-warnings source/scripts/ollama-auth-proxy.mts &>/dev/null & echo $! >ollama-auth-proxy.pid)
for _ in $(seq 30);do l&&exit;sleep 1;done
echo "proxy: not listening";exit
fi
cd "${0%/*}"
. .state/recover.env
. ./params.env
export PATH="$BIN_PATH:$PATH"
# brew-balanced: POST
p=$(openshell policy get "$SANDBOX_NAME" --full)
case $p in *brew-balanced*) openshell policy update "$SANDBOX_NAME" --remove-rule brew-balanced --wait >/dev/null ;; esac
for ep in github.com codeload.github.com; do
openshell policy update "$SANDBOX_NAME" --rule-name readonly-github --add-endpoint "$ep:443:read-only:rest:enforce" --binary /usr/bin/git --binary /usr/bin/curl --wait >/dev/null
done
[ "$AGENT_HARNESS" = langchain-deepagents-code ] || { umask 077;U=$APP_DIR/AGENT_URL.txt;nemoclaw "$SANDBOX_NAME" dashboard-url --quiet >$U.new;mv $U.new $U;}
EOF
chmod 755 "$APP/post-recover.sh"
"$APP/post-recover.sh" pre
C="sg docker -c 'nemoclaw private-agent connect'"
LOC="return 200 \"Terminal only: $C\";"
DONE="Agent ready. In the terminal run: $C"
UP=;case $AGENT_HARNESS in openclaw) UP=18789;; hermes) UP=9119;;esac
[ -z "$UP" ]||{
LOC="if (\$deny) { return 403; } proxy_pass http://127.0.0.1:$UP; proxy_http_version 1.1; proxy_set_header Host 127.0.0.1:$UP; proxy_set_header Origin \$po; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection \$conn; proxy_read_timeout 1h;"
DONE="Agent ready. Open the agent link; access URL in ~/workspace/private-agent/AGENT_URL.txt";}
cat > "$APP/nginx.conf" <<EOF
events {}
http {
map \$http_upgrade \$conn { default upgrade; '' close; }
map \$http_origin \$po { default ''; "~^https://[a-z0-9-]+\.brevlab\.com\$" http://127.0.0.1:$UP; }
map "\$http_origin|\$request_method" \$deny { default 1; "|GET" 0; "~^https://[a-z0-9-]+\.brevlab\.com\|" 0; }
server { listen 127.0.0.1:18780; location / { $LOC } }
}
EOF
# nginx 1.30.7-alpine, index digest 2026-11-18
sudo docker container inspect agent-proxy >/dev/null 2>&1 ||
sudo docker run -d --name agent-proxy --restart unless-stopped --network host -v "$APP/nginx.conf:/etc/nginx/nginx.conf:ro" \
 nginx:1.30.7-alpine@sha256:b24de00298eb7fb23839442d46c780991be7bc7ddb081b6c0876ac777012e352 >/dev/null

NAME=nemotron-vllm
SERVED_NAME=nemotron-3.5-lightning
GPU_UTIL=0.90
MAX_NUM_SEQS=8
ENV_FILE=$APP/vllm.env

# >>> wave3:vllm-nemotron.sh@5cff0907c4ad
# Nemotron 3.5 Lightning 30B-A3B NVFP4 on vLLM, VM form.
# Paste between the wave3 markers of a #!/bin/bash setup script that already
# runs under "set -euo pipefail". Set these variables before this block:
#   NAME          container name and workspace folder, e.g. nemotron-vllm
#   SERVED_NAME   model name clients send in "model", e.g. nemotron-3.5-lightning
#   MAX_MODEL_LEN context window in tokens; always bounded (65536 smoked on L40S)
#   GPU_UTIL      vLLM --gpu-memory-utilization; 0.90 when vLLM has the GPU alone
#   MAX_NUM_SEQS  explicit --max-num-seqs; the vLLM default (1024) can exceed the
#                 Mamba cache blocks of this hybrid model and fail at startup
#   ENV_FILE      mode 0600 file holding HF_TOKEN=<token> or nothing; docker reads
#                 it, the token never appears on a command line or in output
#   VLLM_READY_BUDGET_S  optional; seconds to wait for /health (default 1800)
# The API listens on 127.0.0.1:8000 of the instance only (OpenAI-compatible,
# base URL http://127.0.0.1:8000/v1). Weights are cached under
# /home/ubuntu/workspace/${NAME}/huggingface: kept on stop, removed on delete.
# Callers: send max_tokens >= 4096. The model reasons before it answers, and a
# 512-token cap returns reasoning only, with no answer.
# Never add --trust-remote-code: this checkpoint does not need it.

: "${NAME:?NAME is not set}"
: "${SERVED_NAME:?SERVED_NAME is not set}"
: "${MAX_MODEL_LEN:?MAX_MODEL_LEN is not set}"
: "${GPU_UTIL:?GPU_UTIL is not set}"
: "${MAX_NUM_SEQS:?MAX_NUM_SEQS is not set}"
: "${ENV_FILE:?ENV_FILE is not set}"
VLLM_READY_BUDGET_S="${VLLM_READY_BUDGET_S:-1800}"

# vllm/vllm-openai v0.27.1: the vLLM release named on the model card for this
# checkpoint; smoked on a Brev L40S 2026-11-15.
VLLM_IMAGE="vllm/vllm-openai:v0.27.1@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967"
# Hugging Face commit of the NVFP4 checkpoint smoked on 2026-11-15.
VLLM_MODEL="nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4"
VLLM_REVISION="bee7596271d1495f6992ae224aefde4410e816b8"
VLLM_HF_DIR="/home/ubuntu/workspace/${NAME}/huggingface"

if [ ! -f "$ENV_FILE" ]; then
  echo "vllm: env file $ENV_FILE is missing" >&2
  exit 1
fi
if [ "$(stat -c %a "$ENV_FILE")" != "600" ]; then
  echo "vllm: env file $ENV_FILE must have mode 600" >&2
  exit 1
fi
mkdir -p "$VLLM_HF_DIR"

if sudo docker container inspect "$NAME" >/dev/null 2>&1; then
  echo "vllm: container $NAME exists; starting it if stopped"
  sudo docker start "$NAME" >/dev/null
else
  echo "vllm: starting container $NAME"
  sudo docker run -d --gpus all --name "$NAME" \
    --restart unless-stopped \
    --ipc=host \
    -p 127.0.0.1:8000:8000 \
    --env-file "$ENV_FILE" \
    -e HF_HOME=/root/.cache/huggingface \
    -e VLLM_HUMMING_MOE_GEMM_TYPE=indexed \
    -e VLLM_USE_DEEP_GEMM=0 \
    -v "$VLLM_HF_DIR:/root/.cache/huggingface" \
    --entrypoint vllm \
    "${VLLM_IMAGE:-vllm/vllm-openai:v0.27.1@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967}" \
    serve "$VLLM_MODEL" \
    --revision "$VLLM_REVISION" \
    --served-model-name "$SERVED_NAME" \
    --host 0.0.0.0 \
    --port 8000 \
    --max-model-len "$MAX_MODEL_LEN" \
    --gpu-memory-utilization "$GPU_UTIL" \
    --max-num-seqs "$MAX_NUM_SEQS" \
    --quantization modelopt_fp4 \
    --moe-backend humming \
    --linear-backend humming \
    --mamba-backend flashinfer \
    --mamba-cache-mode align \
    --mamba-ssu-algorithm simple \
    --reasoning-parser nemotron_v3 \
    --enable-prefix-caching \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder >/dev/null
fi

# First start downloads about 18 GiB of weights, then loads them.
echo "vllm: waiting up to ${VLLM_READY_BUDGET_S}s for http://127.0.0.1:8000/health"
vllm_deadline=$(( $(date +%s) + VLLM_READY_BUDGET_S ))
until curl -fsS --max-time 5 http://127.0.0.1:8000/health >/dev/null 2>&1; do
  if [ "$(date +%s)" -ge "$vllm_deadline" ]; then
    echo "vllm: not healthy after ${VLLM_READY_BUDGET_S}s; inspect with: sudo docker logs $NAME" >&2
    exit 1
  fi
  sleep 10
done

vllm_models="$(curl -fsS --max-time 10 http://127.0.0.1:8000/v1/models)" || {
  echo "vllm: /v1/models did not answer" >&2
  exit 1
}
case "$vllm_models" in
  *"\"$SERVED_NAME\""*) echo "vllm: ready, serving $SERVED_NAME on 127.0.0.1:8000" ;;
  *)
    echo "vllm: /v1/models does not list $SERVED_NAME" >&2
    exit 1
    ;;
esac
# <<< wave3:vllm-nemotron.sh

# >>> wave3:openshell-install.sh@630e898da6a4
# OpenShell v0.0.116 from the release .deb, verified by sha256 before install.
# Paste between the wave3 markers of a #!/bin/bash setup script that runs
# under "set -euo pipefail". Run it before any installer that would fetch
# OpenShell itself, so the version on the instance is the pinned one.
# Never use the upstream "curl .../install.sh | sh" line.
# v0.0.116 is the newest OpenShell that NemoClaw v0.0.144 accepts; the .deb
# digest was read from the GitHub release API on 2026-11-18.
OPENSHELL_VERSION="0.0.116"
OPENSHELL_DEB_SHA256="883b5223399dd30a2b33b7f76817fd81295d610ce6f2d04a0266fc7cfbf87575"
if ! command -v openshell >/dev/null 2>&1 || ! openshell --version 2>/dev/null | grep -qF "$OPENSHELL_VERSION"; then
  os_tmp="$(mktemp -d)"
  curl -fsSL --retry 3 -o "$os_tmp/openshell.deb" \
    "https://github.com/NVIDIA/OpenShell/releases/download/v${OPENSHELL_VERSION}/openshell_${OPENSHELL_VERSION}-1_amd64.deb"
  printf '%s  %s\n' "$OPENSHELL_DEB_SHA256" "$os_tmp/openshell.deb" | sha256sum -c --quiet - || {
    echo "openshell: package checksum mismatch" >&2
    rm -rf "$os_tmp"
    exit 1
  }
  sudo apt-get install -y "$os_tmp/openshell.deb"
  rm -rf "$os_tmp"
fi
openshell --version
# <<< wave3:openshell-install.sh

# NemoClaw v0.0.144
NEMOCLAW_SHA=82e1ad7474ec7175c5b860b2bfa9d7940bc6e75f
NEMOCLAW_INSTALL_SHA256=662dfc66b84c4507a6c1a3cc5429ab9ace6034c26a44ed84d446451e32db57d4
# Node >= 22.19
NODE_VERSION=22.23.5
NODE_SHA256=cdeb8670a0c81f51b4dc4ac61919f9b1ad917b304bf8221eb939570663d240f8
APP_DIR=$APP
SANDBOX_NAME=private-agent
AGENT=$AGENT_HARNESS
ENDPOINT_URL=http://localhost:8000/v1
SERVED_MODEL=$SERVED_NAME
POLICY_TIER=balanced
export NEMOCLAW_WEB_SEARCH_PROVIDER=none NEMOCLAW_REASONING_EFFORT=low
[ "$AGENT_HARNESS" != hermes ] || export NEMOCLAW_HERMES_DASHBOARD=1

# >>> wave3:nemoclaw-bootstrap.sh@fe296a465f7c
# NemoClaw + OpenShell bootstrap: Node runtime, pinned installer, onboarding,
# a boot-time recovery unit and readiness checks. Idempotent: each step
# leaves a marker under $APP_DIR/.state. Never prints a setting's value.
for v in NEMOCLAW_SHA NEMOCLAW_INSTALL_SHA256 NODE_VERSION NODE_SHA256 APP_DIR SANDBOX_NAME AGENT ENDPOINT_URL SERVED_MODEL POLICY_TIER; do
  [ -n "${!v:-}" ] || { echo "Missing setting: $v" >&2; exit 1; }
done
[[ $NEMOCLAW_SHA =~ ^[0-9a-f]{40}$ && $NEMOCLAW_INSTALL_SHA256 =~ ^[0-9a-f]{64}$ && $NODE_SHA256 =~ ^[0-9a-f]{64}$ && $SANDBOX_NAME =~ ^[a-z0-9-]+$ && $APP_DIR =~ ^[A-Za-z0-9/._-]+$ && $NODE_VERSION =~ ^([0-9]+)\.([0-9]+)\.[0-9]+$ ]] || { echo "Invalid pin or sandbox name format" >&2; exit 1; }
(( BASH_REMATCH[1] > 22 || (BASH_REMATCH[1] == 22 && BASH_REMATCH[2] >= 19) )) || { echo "Node 22.19 or newer is required" >&2; exit 1; }
VLLM_CONTAINER="${VLLM_CONTAINER:-nemotron-vllm}"
VLLM_HEALTH_URL="${VLLM_HEALTH_URL:-http://localhost:8000/health}"
# Hook: CHAT_UI_URL is passed to the installer only when set; empty by default.
CHAT_UI_URL="${CHAT_UI_URL:-}"
ST="$APP_DIR/.state"
mkdir -p "$ST"
chmod 0700 "$ST"
ME="$(id -un)"
export PATH="$APP_DIR/node/bin:$HOME/.local/bin:$PATH"

if [ ! -e "$ST/node-$NODE_VERSION" ]; then
  t="$ST/node.tar.xz"
  curl -fsSL --retry 3 -o "$t" "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
  printf '%s  %s\n' "$NODE_SHA256" "$t" | sha256sum -c --quiet -
  rm -rf "$APP_DIR/node"
  mkdir -p "$APP_DIR/node"
  tar -xJf "$t" -C "$APP_DIR/node" --strip-components=1
  rm -f "$t"
  touch "$ST/node-$NODE_VERSION"
fi

id -nG "$ME" | grep -qw docker || sudo usermod -aG docker "$ME"

echo "Waiting for the model server"
for _ in $(seq 300); do curl -fsS -o /dev/null --max-time 5 "$VLLM_HEALTH_URL" && break; sleep 5; done
curl -fsS -o /dev/null --max-time 5 "$VLLM_HEALTH_URL" || { echo "Model server not healthy" >&2; exit 1; }

if [ ! -e "$ST/nemoclaw-$NEMOCLAW_SHA" ]; then
  i="$ST/nemoclaw-install.sh"
  curl -fsSL --retry 3 -o "$i" "https://raw.githubusercontent.com/NVIDIA/NemoClaw/$NEMOCLAW_SHA/install.sh"
  printf '%s  %s\n' "$NEMOCLAW_INSTALL_SHA256" "$i" | sha256sum -c --quiet -
  chmod 0700 "$i"
  echo "Installing NemoClaw (output in $ST/nemoclaw-install.log)"
  ( umask 077
    export NEMOCLAW_INSTALL_REF="$NEMOCLAW_SHA" NEMOCLAW_NON_INTERACTIVE=1 NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
      NEMOCLAW_AGENT="$AGENT" NEMOCLAW_SANDBOX_NAME="$SANDBOX_NAME" NEMOCLAW_POLICY_TIER="$POLICY_TIER" \
      NEMOCLAW_PROVIDER=custom NEMOCLAW_ENDPOINT_URL="$ENDPOINT_URL" NEMOCLAW_MODEL="$SERVED_MODEL" \
      NEMOCLAW_COMPATIBLE_AUTH_MODE=none NEMOCLAW_DISABLE_TELEMETRY=1 OPENSHELL_TELEMETRY_ENABLED=false
    [ -z "$CHAT_UI_URL" ] || export CHAT_UI_URL
    sg docker -c "bash '$i'" >"$ST/nemoclaw-install.log" 2>&1
  ) || { echo "NemoClaw install failed; see $ST/nemoclaw-install.log" >&2; exit 1; }
  touch "$ST/nemoclaw-$NEMOCLAW_SHA"
fi

( umask 077
  printf 'APP_DIR=%q\nSANDBOX_NAME=%q\nVLLM_CONTAINER=%q\nVLLM_HEALTH_URL=%q\nBIN_PATH=%q\n' \
    "$APP_DIR" "$SANDBOX_NAME" "$VLLM_CONTAINER" "$VLLM_HEALTH_URL" "$APP_DIR/node/bin:$HOME/.local/bin" >"$ST/recover.env"
)
cat >"$APP_DIR/recover.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/.state/recover.env"
export PATH="$BIN_PATH:$PATH" NEMOCLAW_DISABLE_TELEMETRY=1 OPENSHELL_TELEMETRY_ENABLED=false
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*"; }
# Host-internal only: loopback or the private Docker bridge range.
lo() {
  local a n=0
  for a in $(ss -Hltn "sport = :$1" | awk '{print $4}'); do
    case "$a" in 127.*|"[::1]":*|172.1[6-9].*|172.2[0-9].*|172.3[01].*) n=1 ;; *) log "port $1 is not host-internal"; return 1 ;; esac
  done
  [ "$n" = 1 ] || [ "$2" = 0 ]
}
ready() {
  local s
  lo 8000 1 && lo 8080 0 || return 1
  s="$(openshell sandbox list 2>/dev/null)" || return 1
  grep -Eq "(^|[[:space:]])$SANDBOX_NAME[[:space:]].*(Ready|Running)" <<<"$s" || return 1
  nemoclaw "$SANDBOX_NAME" status >/dev/null 2>&1 || return 1
  nemoclaw "$SANDBOX_NAME" connect --probe-only >/dev/null 2>&1
}
if [ "${1:-}" = --check ]; then ready && exit 0; exit 1; fi
log "recover start"
if ! docker inspect "$VLLM_CONTAINER" >/dev/null 2>&1; then
  [ -x "$APP_DIR/vllm-run.sh" ] || { log "model server container missing"; exit 1; }
  "$APP_DIR/vllm-run.sh"
fi
docker start "$VLLM_CONTAINER" >/dev/null
for _ in $(seq 240); do curl -fsS -o /dev/null --max-time 5 "$VLLM_HEALTH_URL" && break; sleep 5; done
curl -fsS -o /dev/null --max-time 5 "$VLLM_HEALTH_URL" || { log "model server not healthy"; exit 1; }
nemoclaw "$SANDBOX_NAME" status >/dev/null 2>&1 || nemoclaw "$SANDBOX_NAME" recover >/dev/null 2>&1 || log "sandbox recover returned non-zero"
for _ in $(seq 60); do ready && break; sleep 5; done
ready || { log "agent sandbox not ready"; exit 1; }
[ ! -x "$APP_DIR/post-recover.sh" ] || "$APP_DIR/post-recover.sh"
log "recover ok"
EOF
chmod 0755 "$APP_DIR/recover.sh"

sed -e "s|@NAME@|$SANDBOX_NAME|g" -e "s|@USER@|$ME|g" -e "s|@APP_DIR@|$APP_DIR|g" >"$ST/agent-recover.service" <<'EOF'
[Unit]
Description=Recover the @NAME@ agent sandbox after boot
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=@USER@
ExecStart=@APP_DIR@/recover.sh
StandardOutput=append:/var/log/@NAME@-recover.log
StandardError=inherit
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
sudo install -m 0644 "$ST/agent-recover.service" "/etc/systemd/system/$SANDBOX_NAME-recover.service"
sudo systemctl daemon-reload
sudo systemctl enable "$SANDBOX_NAME-recover.service"

# Health check: full recovery pass, then the readiness gate.
sg docker -c "'$APP_DIR/recover.sh'" || { echo "Agent sandbox not ready" >&2; exit 1; }
sg docker -c "'$APP_DIR/recover.sh' --check" || { echo "Agent sandbox readiness check failed" >&2; exit 1; }
echo "NemoClaw sandbox ready"
# <<< wave3:nemoclaw-bootstrap.sh

sed -i -e 's/lo 8080 0 ||/lo 8080 0 \&\& lo 18780 1 ||/' -e '2a [ "$(id -gn)" = docker ] || exec sg docker -c "$0 $*"' -e '/|| nemoclaw/i "$APP_DIR/post-recover.sh" pre' "$APP/recover.sh"
[ "$(grep -c 'lo 18780 1 ||\|exec sg docker\|sh" pre$' "$APP/recover.sh")" = 3 ]||{ echo "Patch failed" >&2;exit 1;}
"$APP/recover.sh" --check||{ echo "Agent not ready" >&2;exit 1;}
echo "$DONE"
