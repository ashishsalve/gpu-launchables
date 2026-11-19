#!/bin/bash
# CUDA Kernel Engineer Agent on Nemotron - setup script (Brev VM mode).
# A third-party open-source coding agent (LangChain Deep Agents Code) runs in
# an NVIDIA OpenShell sandbox with GPU access and the CUDA toolchain, and uses
# NVIDIA Nemotron 3.5 Lightning served by vLLM on this GPU (localhost only).
#
# Launch parameters (read from this script's environment):
#   AGENT          deepagents-code (default)
#   MODEL          nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 (default)
#   MAX_MODEL_LEN  65536 (default), 32768 or 131072
#   HF_TOKEN       optional Hugging Face read token, no default; stored only in
#                  a mode 600 file and never printed
#
# Everything lives under /home/ubuntu/workspace (survives Stop, removed by
# Delete). code-server (13337) and the Kernel Report (3000), both with a
# generated password, listen on all interfaces so Brev Secure Links can reach them; vLLM stays on
# localhost and the model proxy on the Docker bridge address only.
set -euo pipefail

AGENT="${AGENT:-deepagents-code}"
MODEL="${MODEL:-nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-65536}"
HF_TOKEN="${HF_TOKEN:-}"

MODEL_REVISION="bee7596271d1495f6992ae224aefde4410e816b8"
# Sandbox image built from this Launchable's image directory, pinned by digest.
SANDBOX_DIGEST="49e43a9670641d2f68502662971e8ebfc53919833df213cd27fdff68eb69f48e"
SANDBOX_REF="ghcr.io/ashishsalve/cuda-kernel-agent-sandbox:dev-sha-e2307ba@sha256:$SANDBOX_DIGEST"
NEMOCLAW_SHA="82e1ad7474ec7175c5b860b2bfa9d7940bc6e75f"
NEMOCLAW_INSTALL_SHA256="662dfc66b84c4507a6c1a3cc5429ab9ace6034c26a44ed84d446451e32db57d4"
NODE_VERSION="22.23.5"
NODE_SHA256="cdeb8670a0c81f51b4dc4ac61919f9b1ad917b304bf8221eb939570663d240f8"
PROXY_PORT="8100"
CODE_SERVER_VERSION="4.145.2"
CODE_SERVER_SHA256="7eddbdeaab34380bde3ac3bbadce58fe2f5722c4877f331ea593ae797c2517e1"

WS="/home/ubuntu/workspace"
LAB="$WS/kernel-lab"
ENV_DIR="/etc/kernel-lab"
ME="$(id -un)"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this setup script as the instance's default user, not root" >&2
  exit 1
fi
case "$AGENT" in deepagents-code) ;; *) echo "Unsupported AGENT: $AGENT" >&2; exit 1 ;; esac
case "$MODEL" in nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) ;; *) echo "Unsupported MODEL: $MODEL" >&2; exit 1 ;; esac
case "$MAX_MODEL_LEN" in 65536|32768|131072) ;; *) echo "Unsupported MAX_MODEL_LEN: $MAX_MODEL_LEN" >&2; exit 1 ;; esac
for v in SANDBOX_DIGEST NEMOCLAW_SHA NEMOCLAW_INSTALL_SHA256 NODE_VERSION NODE_SHA256; do
  [ -n "${!v}" ] || { echo "Release pin $v is not set in this script" >&2; exit 1; }
done

# Preconditions. The base image provides the driver, Docker and the NVIDIA
# Container Toolkit; this script never reinstalls them.
command -v nvidia-smi >/dev/null || { echo "nvidia-smi not found" >&2; exit 1; }
DRIVER="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader --id=0)"
[ "${DRIVER%%.*}" -ge 580 ] || { echo "NVIDIA driver $DRIVER found; 580 or newer is required" >&2; exit 1; }
DOCKER_VERSION="$(sudo docker version --format '{{.Server.Version}}')"
[ "${DOCKER_VERSION%%.*}" -ge 28 ] || { echo "Docker $DOCKER_VERSION found; 28 or newer is required" >&2; exit 1; }

mkdir -p "$LAB/host" "$LAB/results" "$LAB/report-site" "$WS/huggingface"

# Settings persist for restarts in mode 600 files (never printed).
sudo mkdir -p "$ENV_DIR"
umask 077
TMP_ENV="$(mktemp)"
cat > "$TMP_ENV" <<EOF
AGENT=$AGENT
MODEL=$MODEL
MAX_MODEL_LEN=$MAX_MODEL_LEN
SANDBOX_REF=$SANDBOX_REF
NEMOCLAW_SHA=$NEMOCLAW_SHA
NEMOCLAW_INSTALL_SHA256=$NEMOCLAW_INSTALL_SHA256
NODE_VERSION=$NODE_VERSION
NODE_SHA256=$NODE_SHA256
PROXY_PORT=$PROXY_PORT
EOF
sudo install -m 600 -o "$ME" "$TMP_ENV" "$ENV_DIR/env"
cat > "$TMP_ENV" <<EOF
HF_TOKEN=$HF_TOKEN
HF_HOME=/root/.cache/huggingface
VLLM_HUMMING_MOE_GEMM_TYPE=indexed
VLLM_USE_DEEP_GEMM=0
EOF
sudo install -m 600 -o root "$TMP_ENV" "$ENV_DIR/vllm.env"
rm -f "$TMP_ENV"
umask 022

# GPU access for the sandbox through CDI; Docker restarts before vLLM starts.
if [ ! -f /etc/cdi/nvidia.yaml ]; then
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
  sudo nvidia-ctk runtime configure --runtime=docker --cdi.enabled
  sudo systemctl restart docker
fi

# vLLM serving the model as "coder" on localhost:8000 only.
if ! sudo docker inspect vllm >/dev/null 2>&1; then
  sudo docker run -d --name vllm --restart unless-stopped --gpus all --ipc=host -p 127.0.0.1:8000:8000 --env-file "$ENV_DIR/vllm.env" -v "$WS/huggingface:/root/.cache/huggingface" vllm/vllm-openai:v0.27.1@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967 \
    --model "$MODEL" --revision "$MODEL_REVISION" --served-model-name coder \
    --quantization modelopt_fp4 --moe-backend humming --linear-backend humming \
    --mamba-backend flashinfer --mamba-cache-mode align --mamba-ssu-algorithm simple \
    --reasoning-parser nemotron_v3 --enable-auto-tool-choice --tool-call-parser qwen3_coder \
    --max-model-len "$MAX_MODEL_LEN" --gpu-memory-utilization 0.55 --max-num-seqs 8 \
    --enable-prefix-caching --port 8000
fi

# Model route for the sandbox: vLLM stays on 127.0.0.1. A small nginx proxy
# listens only on the Docker bridge gateway address (reachable from local
# containers, not from outside the instance) and forwards to 127.0.0.1:8000.
BRIDGE_IP="$(sudo docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}')"
case "$BRIDGE_IP" in 172.*|10.*|192.168.*) ;; *) echo "Unexpected Docker bridge gateway address" >&2; exit 1 ;; esac
cat > "$LAB/model-proxy.conf" <<EOF
events {}
http {
  access_log off;
  server {
    listen $BRIDGE_IP:$PROXY_PORT;
    location / {
      proxy_pass http://127.0.0.1:8000;
      proxy_http_version 1.1;
      proxy_buffering off;
      proxy_read_timeout 900s;
    }
  }
}
EOF
if ! sudo docker inspect model-proxy >/dev/null 2>&1; then
  sudo docker run -d --name model-proxy --restart unless-stopped --network host --read-only \
    --tmpfs=/var/cache/nginx --tmpfs=/var/run -v "$LAB/model-proxy.conf:/etc/nginx/nginx.conf:ro" \
    nginx:1.30.7-alpine@sha256:b24de00298eb7fb23839442d46c780991be7bc7ddb081b6c0876ac777012e352
fi

# Sandbox image at a fixed digest; host scripts are copied out of it.
[ "$SANDBOX_REF" = "ghcr.io/ashishsalve/cuda-kernel-agent-sandbox:dev-sha-e2307ba@sha256:$SANDBOX_DIGEST" ] || { echo "Sandbox image reference mismatch" >&2; exit 1; }
sudo docker pull "ghcr.io/ashishsalve/cuda-kernel-agent-sandbox:dev-sha-e2307ba@sha256:49e43a9670641d2f68502662971e8ebfc53919833df213cd27fdff68eb69f48e"
GOT="$(sudo docker image inspect --format '{{join .RepoDigests " "}}' "$SANDBOX_REF")"
case " $GOT " in *"@sha256:$SANDBOX_DIGEST "*) ;; *) echo "Sandbox image digest does not match the pinned digest" >&2; exit 1 ;; esac
CID="$(sudo docker create "ghcr.io/ashishsalve/cuda-kernel-agent-sandbox:dev-sha-e2307ba@sha256:49e43a9670641d2f68502662971e8ebfc53919833df213cd27fdff68eb69f48e")"
sudo docker cp "$CID:/opt/kernel-lab/host/." "$LAB/host/"
sudo docker rm "$CID" >/dev/null
sudo chown -R "$ME:$ME" "$LAB"

# The NemoClaw installer refuses a group- or world-writable user-local
# directory; the base image creates $HOME/.local with mode 775.
mkdir -p "$HOME/.local/bin"
chmod 755 "$HOME" "$HOME/.local" "$HOME/.local/bin"

# NemoClaw at a fixed commit, agent onboarding and the GPU sandbox.
"$LAB/host/up.sh"

# code-server from the pinned release package, checksum verified.
if ! dpkg-query -W -f '${Version}' code-server 2>/dev/null | grep -qx "$CODE_SERVER_VERSION"; then
  DEB="$LAB/code-server.deb"
  curl -fsSL --retry 3 -o "$DEB" "https://github.com/coder/code-server/releases/download/v$CODE_SERVER_VERSION/code-server_${CODE_SERVER_VERSION}_amd64.deb"
  sha256sum -c --status <<<"$CODE_SERVER_SHA256  $DEB" || { echo "code-server package failed its SHA-256 check" >&2; exit 1; }
  sudo dpkg -i "$DEB"
  rm -f "$DEB"
fi
mkdir -p "$HOME/.config/code-server" "$HOME/.local/share/code-server/User"
# code-server listens on all interfaces because the Brev Secure Link tunnel
# connects on a non-loopback address; a password generated here protects it.
# The password is kept on re-run (never rotated) and never printed.
CS_CONF="$HOME/.config/code-server/config.yaml"
CS_PW=""
if [ -f "$CS_CONF" ]; then
  CS_PW="$(sed -n 's/^password: //p' "$CS_CONF")"
fi
if [ -z "$CS_PW" ]; then
  CS_PW="$(head -c 32 /dev/urandom | base64 | tr -dc A-Za-z0-9 | cut -c1-24)"
fi
umask 077
cat > "$CS_CONF" <<EOF
bind-addr: 0.0.0.0:13337
auth: password
password: $CS_PW
cert: false
EOF
chmod 600 "$CS_CONF"
umask 022
unset CS_PW
# Kernel Report: read-only server for report-site behind HTTP Basic auth
# (user report). Its password is generated here, kept on re-run, mode 600,
# read from the file at startup and never printed or passed on a command line.
RP_FILE="$HOME/.config/kernel-report/password"
umask 077
mkdir -p "$HOME/.config/kernel-report"
if [ ! -s "$RP_FILE" ]; then
  head -c 32 /dev/urandom | base64 | tr -dc A-Za-z0-9 | cut -c1-24 > "$RP_FILE"
fi
chmod 600 "$RP_FILE"
umask 022
cat > "$LAB/report-server.py" <<'PY'
import base64, hmac, sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
root, pwfile = sys.argv[1], sys.argv[2]
port = int(sys.argv[3]) if len(sys.argv) > 3 else 3000
with open(pwfile) as f:
    pw = f.read().strip()
if not pw:
    sys.exit("Kernel Report password file is empty")
want = b"Basic " + base64.b64encode(b"report:" + pw.encode())
del pw

class Handler(SimpleHTTPRequestHandler):
    def send_head(self):
        got = self.headers.get("Authorization", "").encode("latin-1", "replace")
        if not hmac.compare_digest(got, want):
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="Kernel Report"')
            self.send_header("Content-Length", "0")
            self.end_headers()
            return None
        return super().send_head()

    def list_directory(self, path):
        self.send_error(404)
        return None

    def end_headers(self):
        self.send_header("X-Content-Type-Options", "nosniff")
        if self.path.split("?")[0].startswith("/files/"):
            self.send_header("Content-Disposition", "attachment")
        super().end_headers()

ThreadingHTTPServer(("0.0.0.0", port), partial(Handler, directory=root)).serve_forever()
PY
cat > "$HOME/.local/share/code-server/User/settings.json" <<EOF
{
  "terminal.integrated.profiles.linux": { "kernel-lab": { "path": "$LAB/host/attach.sh" } },
  "terminal.integrated.defaultProfile.linux": "kernel-lab",
  "telemetry.telemetryLevel": "off"
}
EOF

unit() {
  sudo tee "/etc/systemd/system/$1.service" >/dev/null
}
unit kernel-lab <<EOF
[Unit]
Description=kernel-lab sandbox recovery
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$ME
ExecStart=$LAB/host/up.sh --recover
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
unit kernel-report <<EOF
[Unit]
Description=Kernel Report (port 3000, Brev Secure Link)
After=network-online.target

[Service]
User=$ME
ExecStartPre=/usr/bin/python3 $LAB/host/generate.py $LAB/results $LAB/report-site
ExecStart=/usr/bin/python3 -I $LAB/report-server.py $LAB/report-site $RP_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOF
unit code-server-lab <<EOF
[Unit]
Description=code-server (port 13337, Brev Secure Link)
After=network-online.target

[Service]
User=$ME
ExecStart=/usr/bin/code-server --config $HOME/.config/code-server/config.yaml $LAB
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable kernel-lab.service kernel-report.service code-server-lab.service
sudo systemctl restart kernel-report.service code-server-lab.service

# Health: model lists "coder" (bounded wait), the report page answers,
# code-server answers.
wait_coder() {
  local _
  for _ in $(seq 1 90); do
    if curl -fsS --max-time 5 "$1" | grep -q '"id":"coder"'; then return 0; fi
    sleep 10
  done
  echo "Model server at $1 did not list 'coder' within 15 minutes; see: sudo docker logs vllm" >&2
  return 1
}
wait_coder http://localhost:8000/v1/models
wait_coder "http://$BRIDGE_IP:$PROXY_PORT/v1/models"
# The report login goes to curl on stdin (-K -), never on its command line.
report_get() {
  curl -fsS --max-time 5 -K - http://localhost:3000/ <<<"user = \"report:$(cat "$RP_FILE")\""
}
for _ in $(seq 1 30); do
  if report_get | grep -q "Kernel Report" && \
     curl -fsS --max-time 5 -o /dev/null http://localhost:13337/healthz; then
    echo "CUDA kernel lab is ready: open the open-code-server link for the agent, the open-kernel-report link for the report."
    exit 0
  fi
  sleep 5
done
echo "Kernel Report or code-server did not answer on localhost" >&2
exit 1
