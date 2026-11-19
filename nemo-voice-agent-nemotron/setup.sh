#!/bin/bash
# NeMo Voice Agent on Nemotron - talk to a voice agent on one GPU.
# NVIDIA NeMo Voice Agent (Pipecat server + web client) with streaming speech
# recognition, Nemotron 3 Diarization, Nemotron 3.5 Lightning on vLLM and
# Kokoro or Magpie text to speech. One HTTPS port (8080, Caddy) serves the
# web client, answers /connect and proxies the audio WebSocket on /ws; vLLM,
# the FastAPI server and the WebSocket server listen on localhost only.
#
# Launch parameters (read from this script's environment):
#   HF_TOKEN     - optional Hugging Face read token for model downloads.
#   TTS_VOICE    - kokoro (default) or magpie.
#   DIARIZATION  - on (default) or off.
# They are saved to ~/workspace/nemo-voice-agent.env (mode 600) so services
# come back after Stop/Start without re-entry. Everything else lives under
# ~/workspace/nemo-voice-agent, which survives Stop and is removed by Delete.
set -euo pipefail

APP_REPO="https://github.com/NVIDIA-NeMo/labs-Voice-Agent.git"
APP_SHA="1231dfb196aa175cb0ef62453fa96c7e4afb660b"
LLM_IMAGE="vllm/vllm-openai:v0.27.1@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967"
LLM_MODEL="nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4"
LLM_REV="bee7596271d1495f6992ae224aefde4410e816b8"
UV_VERSION="0.13.8"
UV_SHA256="5acfd9177cfecf0bf87578f059728215ccc884388988f55f7a65041b57387d91"
NODE_VERSION="v22.23.5"
NODE_SHA256="cdeb8670a0c81f51b4dc4ac61919f9b1ad917b304bf8221eb939570663d240f8"
CADDY_VERSION="2.11.9"
CADDY_SHA512="0e85544340290a16ce4bfb76fe7d65e9de1bf3a6e67f5ccfff30b30d27ea4c73e078077b7bf3e58ae60b6b12e44327705287059c775bca5782e8ee85ea7edd75"
HF_HUB_VERSION="2.4.0"
SPACY_SM_SHA256="1932429db727d4bff3deed6b34cfc05df17794f4a52eeb26cf8928f7c1a0fb85"
# Hugging Face models, each at a fixed commit: "repo revision".
MODELS=(
  "nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 bee7596271d1495f6992ae224aefde4410e816b8"
  "nvidia/parakeet_realtime_eou_120m-v1 a7e2b4629593dce0ec19f600e00e9904353fda2d"
  "nvidia/Nemotron-3-Diarization 52a432672732425e4c19765b9fec9b5810e6f4ba"
  "hexgrad/Kokoro-82M f3ff3571791e39611d31c381e3a41a3af07b4987"
)
MAGPIE="nvidia/magpie_tts_multilingual_357m 446bff55e1fe3d3aa29c771574e7d2b0fa322990"

WS="$HOME/workspace"
NVA="$WS/nemo-voice-agent"
APP="$NVA/src"
SRV="$APP/examples/generic_voice_agent/server"
CLIENT="$APP/examples/generic_voice_agent/client"
TOOLS="$NVA/tools"
BIN="$NVA/bin"
CONF="$NVA/config"
ENVF="$WS/nemo-voice-agent.env"
export HF_HOME="$NVA/huggingface"
export UV_CACHE_DIR="$NVA/.cache/uv"
export UV_PYTHON_INSTALL_DIR="$TOOLS/python"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this setup script as the instance's default user, not root" >&2
  exit 1
fi
mkdir -p "$WS" "$NVA" "$TOOLS/bin" "$BIN" "$CONF" "$HF_HOME" "$NVA/smoke"

# Parameters: keep earlier values on a re-run when a parameter is empty.
umask 077
if [ -f "$ENVF" ]; then
  OLD_HF="$(sed -n 's/^HF_TOKEN=//p' "$ENVF")"
  OLD_TTS="$(sed -n 's/^TTS_VOICE=//p' "$ENVF")"
  OLD_DIAR="$(sed -n 's/^DIARIZATION=//p' "$ENVF")"
else
  OLD_HF=""; OLD_TTS=""; OLD_DIAR=""
fi
HF_TOKEN="${HF_TOKEN:-$OLD_HF}"
TTS_VOICE="${TTS_VOICE:-${OLD_TTS:-kokoro}}"
DIARIZATION="${DIARIZATION:-${OLD_DIAR:-on}}"
case "$TTS_VOICE" in kokoro|magpie) ;; *) echo "Unsupported TTS_VOICE: $TTS_VOICE" >&2; exit 1 ;; esac
case "$DIARIZATION" in on|off) ;; *) echo "Unsupported DIARIZATION: $DIARIZATION" >&2; exit 1 ;; esac
case "$HF_TOKEN" in
  *[[:space:]]*) echo "HF_TOKEN contains a space or line break; paste the token alone and redeploy" >&2; exit 1 ;;
esac
cat > "$ENVF" <<EOF
HF_TOKEN=${HF_TOKEN}
TTS_VOICE=${TTS_VOICE}
DIARIZATION=${DIARIZATION}
EOF
chmod 600 "$ENVF"
umask 022
if [ -n "$HF_TOKEN" ]; then export HF_TOKEN; else unset HF_TOKEN; fi

# GPU checks. The base image provides the driver, Docker and the NVIDIA
# Container Toolkit; this script never reinstalls them.
command -v nvidia-smi >/dev/null || { echo "nvidia-smi not found" >&2; exit 1; }
VRAM_MIB="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits --id=0)"
CC="$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader --id=0)"
if [ "${VRAM_MIB%%.*}" -lt 44000 ]; then
  echo "GPU has ${VRAM_MIB} MiB; this stack needs a 48 GB class GPU" >&2
  exit 1
fi
# Ada (compute capability 8.9) has no native FP4: use the W4A16 kernels.
ADA_FLAGS=""
if [ "$CC" = "8.9" ]; then
  ADA_FLAGS="--moe-backend humming --linear-backend humming --mamba-backend flashinfer --mamba-cache-mode align --mamba-ssu-algorithm simple"
fi

# Download to a file, verify the checksum, then use it.
fetch() {
  local url="$1" algo="$2" sum="$3" out="$4"
  curl -fsSL --retry 3 -o "$out.part" "$url"
  if ! "${algo}sum" -c --status <<<"$sum  $out.part"; then
    rm -f "$out.part"
    echo "Checksum mismatch for $url" >&2
    exit 1
  fi
  mv "$out.part" "$out"
}

if [ ! -x "$TOOLS/bin/uv" ] || [ "$("$TOOLS/bin/uv" --version | cut -d' ' -f2)" != "$UV_VERSION" ]; then
  fetch "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz" sha256 "$UV_SHA256" "$TOOLS/uv.tgz"
  tar -xzf "$TOOLS/uv.tgz" -C "$TOOLS/bin" --strip-components=1 uv-x86_64-unknown-linux-gnu/uv uv-x86_64-unknown-linux-gnu/uvx
  rm -f "$TOOLS/uv.tgz"
fi
if [ ! -x "$TOOLS/node/bin/node" ] || [ "$("$TOOLS/node/bin/node" --version)" != "$NODE_VERSION" ]; then
  fetch "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz" sha256 "$NODE_SHA256" "$TOOLS/node.txz"
  rm -rf "$TOOLS/node"
  mkdir -p "$TOOLS/node"
  tar -xJf "$TOOLS/node.txz" -C "$TOOLS/node" --strip-components=1
  rm -f "$TOOLS/node.txz"
fi
if [ ! -x "$TOOLS/bin/caddy" ] || ! "$TOOLS/bin/caddy" version | grep -q "^v$CADDY_VERSION"; then
  fetch "https://github.com/caddyserver/caddy/releases/download/v$CADDY_VERSION/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" sha512 "$CADDY_SHA512" "$TOOLS/caddy.tgz"
  tar -xzf "$TOOLS/caddy.tgz" -C "$TOOLS/bin" caddy
  rm -f "$TOOLS/caddy.tgz"
fi
cat > "$TOOLS/bin/hf" <<EOF
#!/bin/bash
exec "$TOOLS/bin/uvx" --from "huggingface_hub==$HF_HUB_VERSION" hf "\$@"
EOF
chmod 755 "$TOOLS/bin/hf"
export PATH="$TOOLS/bin:$TOOLS/node/bin:$PATH"

# NeMo Voice Agent source at a fixed commit (the project has no release tags).
[ -d "$APP/.git" ] || git init -q "$APP"
if [ "$(git -C "$APP" rev-parse -q --verify HEAD || true)" != "$APP_SHA" ]; then
  git -C "$APP" fetch -q --depth 1 "$APP_REPO" "$APP_SHA"
  git -C "$APP" checkout -q --detach "$APP_SHA"
fi
if [ "$(git -C "$APP" rev-parse HEAD)" != "$APP_SHA" ]; then
  echo "NeMo Voice Agent checkout is not commit $APP_SHA" >&2
  exit 1
fi

# Python environment exactly as locked upstream (uv.lock, Python 3.12).
(cd "$APP" && uv sync --frozen)
PY="$APP/.venv/bin/python"
# Licence guard: refuse a GPL phonemizer in the environment.
if "$PY" -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('phonemizer') else 1)"; then
  echo "phonemizer (GPL) is present in the environment; refusing to continue" >&2
  exit 1
fi
# spaCy English model for the Kokoro G2P (misaki): pinned wheel, checked by
# sha256, installed after uv sync (a frozen sync removes extra packages).
SPACY_SM_WHL="$TOOLS/wheels/en_core_web_sm-3.8.0-py3-none-any.whl"
mkdir -p "$TOOLS/wheels"
fetch "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl" sha256 "$SPACY_SM_SHA256" "$SPACY_SM_WHL"
uv pip install -q --python="$PY" --no-index --find-links="$TOOLS/wheels" "en_core_web_sm==3.8.0"
"$PY" -c "import en_core_web_sm" || { echo "en_core_web_sm is not importable" >&2; exit 1; }
# NLTK data for g2p in an absolute, symlink-free directory on NLTK's search
# path, verified afterwards (the -q downloader can exit 0 after a failure).
mkdir -p "$NVA/nltk_data"
NLTK_DIR="$(realpath -e "$NVA/nltk_data")"
export NLTK_DATA="$NLTK_DIR"
NLTK_DATA="$NLTK_DIR" "$PY" -m nltk.downloader -q -d "$NLTK_DIR" averaged_perceptron_tagger averaged_perceptron_tagger_eng cmudict
if ! NLTK_DATA="$NLTK_DIR" "$PY" -c 'import nltk; [nltk.data.find(p) for p in ("corpora/cmudict","taggers/averaged_perceptron_tagger","taggers/averaged_perceptron_tagger_eng")]'; then
  echo "NLTK data download failed: see $NLTK_DIR" >&2
  exit 1
fi

# Models at fixed revisions. refs/main points at the pinned revision so the
# services resolve it with HF_HUB_OFFLINE=1.
get_model() {
  local repo="$1"
  local MODEL_REV="$2"
  hf download "$repo" --revision "$MODEL_REV" >/dev/null
  mkdir -p "$HF_HOME/hub/models--${repo//\//--}/refs"
  printf '%s' "$MODEL_REV" > "$HF_HOME/hub/models--${repo//\//--}/refs/main"
}
for m in "${MODELS[@]}"; do get_model $m; done
if [ "$TTS_VOICE" = "magpie" ]; then get_model $MAGPIE; fi

# Web client: same-origin connection through the HTTPS link. Exactly one line
# changes; the build stops if upstream no longer matches.
"$PY" - "$CLIENT/src/app.ts" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = "baseUrl: `http://${window.location.hostname}:7860`,"
new = "baseUrl: window.location.origin,"
if s.count(old) == 1:
    open(p, "w").write(s.replace(old, new))
elif s.count(new) != 1:
    sys.exit("client patch: expected line not found exactly once")
PYEOF
(cd "$CLIENT" && npm ci --no-audit --no-fund && npm run build)
[ -f "$CLIENT/dist/index.html" ] || { echo "Client build produced no dist/index.html" >&2; exit 1; }

# Server config: upstream default.yaml plus this Launchable's choices.
"$PY" - "$SRV" "$CONF" "$TTS_VOICE" "$DIARIZATION" <<'PYEOF'
import sys
from omegaconf import OmegaConf
srv, conf, tts, diar = sys.argv[1:5]
c = OmegaConf.load(f"{srv}/server_configs/default.yaml")
llm = OmegaConf.load(f"{srv}/server_configs/llm_configs/nemotron_3.5_lightning.yaml")
llm.max_new_tokens = 4096
# The server resolves only the basename under server_configs/llm_configs/.
OmegaConf.save(llm, f"{srv}/server_configs/llm_configs/nva-launchable-llm.yaml")
c.llm.model_config = "./server_configs/llm_configs/nva-launchable-llm.yaml"
c.diar.enabled = diar == "on"
if tts == "magpie":
    c.tts.model = "nvidia/magpie_tts_multilingual_357m"
    c.tts.model_config = f"{srv}/server_configs/tts_configs/magpie_tts_multilingual_357m.yaml"
OmegaConf.save(c, f"{conf}/nva-server.yaml")
PYEOF
cat > "$CONF/server.env" <<EOF
SERVER_HOST=127.0.0.1
SERVER_CONFIG_PATH=$CONF/nva-server.yaml
HF_HOME=$HF_HOME
HF_HUB_OFFLINE=1
NLTK_DATA=$NLTK_DIR
EOF

cat > "$CONF/Caddyfile" <<EOF
{
	admin off
	auto_https off
}
:8080 {
	handle /connect {
		header Content-Type application/json
		respond "{\"ws_url\":\"wss://{host}/ws\"}" 200
	}
	handle /ws {
		rewrite * /
		reverse_proxy localhost:8765
	}
	handle_path /__smoke/* {
		root * $NVA/smoke
		file_server
	}
	handle {
		root * $CLIENT/dist
		try_files {path} /index.html
		file_server
	}
}
EOF

cat > "$BIN/wait-http" <<'EOF'
#!/bin/bash
# wait-http URL SECONDS: wait until URL answers 2xx.
set -euo pipefail
end=$(( $(date +%s) + $2 ))
until curl -fsS --max-time 5 -o /dev/null "$1"; do
  [ "$(date +%s)" -lt "$end" ] || { echo "Timed out waiting for $1" >&2; exit 1; }
  sleep 10
done
EOF
cat > "$BIN/nva-llm" <<EOF
#!/bin/bash
set -euo pipefail
exec docker run --rm --name nva-llm --gpus all --ipc=host -p 127.0.0.1:8000:8000 -v $HF_HOME:/root/.cache/huggingface -e HF_HUB_OFFLINE=1 -e VLLM_HUMMING_MOE_GEMM_TYPE=indexed -e VLLM_USE_DEEP_GEMM=0 --entrypoint vllm vllm/vllm-openai:v0.27.1@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967 serve $LLM_MODEL --revision $LLM_REV --served-model-name $LLM_MODEL --quantization modelopt_fp4 $ADA_FLAGS --reasoning-parser nemotron_v3 --port 8000 --max-model-len 32768 --gpu-memory-utilization 0.70 --max-num-seqs 1 --enable-prefix-caching --enable-auto-tool-choice --tool-call-parser qwen3_coder
EOF
chmod 755 "$BIN/wait-http" "$BIN/nva-llm"
sudo docker pull vllm/vllm-openai:v0.27.1@sha256:0a51ea5b4ae2dc5d81890e5173f54203d2a3ae0cfffe51b8fd2afd4391bfd967

unit() {
  sudo tee "/etc/systemd/system/$1.service" >/dev/null
}
unit nva-llm <<EOF
[Unit]
Description=NeMo Voice Agent - Nemotron 3.5 Lightning on vLLM (localhost:8000)
After=docker.service network-online.target
Requires=docker.service
[Service]
ExecStartPre=-/usr/bin/docker rm -f nva-llm
ExecStart=$BIN/nva-llm
ExecStop=/usr/bin/docker stop nva-llm
Restart=always
RestartSec=10
TimeoutStartSec=0
[Install]
WantedBy=multi-user.target
EOF
unit nva-server <<EOF
[Unit]
Description=NeMo Voice Agent - Pipecat server (localhost:7860, localhost:8765)
After=nva-llm.service
Wants=nva-llm.service
[Service]
User=$(id -un)
WorkingDirectory=$SRV
EnvironmentFile=$CONF/server.env
Environment=NLTK_DATA=$NLTK_DIR
ExecStartPre=$BIN/wait-http http://localhost:8000/health 3600
ExecStart=$PY server.py
Restart=on-failure
RestartSec=15
TimeoutStartSec=0
[Install]
WantedBy=multi-user.target
EOF
unit nva-proxy <<EOF
[Unit]
Description=NeMo Voice Agent - Caddy on port 8080 (client, /connect, /ws)
After=network-online.target
[Service]
User=$(id -un)
ExecStart=$TOOLS/bin/caddy run --config $CONF/Caddyfile --adapter caddyfile
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable nva-llm.service nva-server.service nva-proxy.service
sudo systemctl restart --no-block nva-llm.service nva-server.service nva-proxy.service

# Health check: the agent server answers on localhost:7860 (45 minutes max).
"$BIN/wait-http" http://localhost:8000/v1/models 2700
"$BIN/wait-http" http://localhost:7860/docs 2700
"$BIN/wait-http" http://localhost:8080/ 300
echo "NeMo Voice Agent is ready: open the nemo-voice-agent link."
