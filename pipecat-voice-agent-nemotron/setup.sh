#!/bin/bash
# Pipecat Voice Agent with Nemotron Speech - speech to speech on one GPU.
# Runs the NVIDIA Nemotron Voice Agent blueprint (single-GPU profile):
# Nemotron Speech ASR and Magpie TTS on NeMo-Speech.cpp, Nemotron 3.5
# Lightning on vLLM, and the Pipecat WebRTC app on port 7860, plus a coturn
# TURN relay so browser audio reaches the instance.
#
# Launch parameters (read from this script's environment):
#   HF_TOKEN       - Hugging Face read token, no default. Used for model
#                    downloads; stored only in the blueprint .env (mode 600).
#   VOICE_PROFILE  - generic-assistant/single-gpu (English, default) or
#                    multilingual-assistant/single-gpu.
#
# Invocation: the blueprint's own documented single-GPU command, from
# docs/01-getting-started.md section 4.3 at the pinned commit:
#   docker compose --profile generic-assistant/single-gpu up -d
#   docker compose --profile multilingual-assistant/single-gpu up -d
# These are the literal profile names in the blueprint docker-compose.yml
# (services generic-assistant-single-gpu and multilingual-assistant-single-gpu,
# SERVICE_RECIPE=single-gpu). The "turn" profile (docker/docker-compose.coturn.yaml)
# adds the coturn relay. Before "up", the boot script resolves the profiles
# with "docker compose config --services" and stops if the app service is missing.
#
# Pins:
#   Blueprint tag v2.3.1, commit 1f5bd71050d79d94890675800b20533178f28abe
#   (released 2026-10-29). The tag's compose files pin vllm/vllm-openai:v0.31.0
#   and nvcr.io/nvidia/nemo-speech.cpp:0.2.0; the app image is built from the
#   tagged source (uv sync --frozen).
#   coturn: upstream uses the major tag instrumentisto/coturn:4; a Compose
#   override written below pins it to 4.5.2 by digest (Docker Hub, 2026-11-15:
#   tags 4, 4.5 and 4.5.2 share this digest, single amd64 image).
#   uv 0.13.8 release archive, SHA-256 checked (needed by the blueprint's
#   model download script); the hf CLI runs as huggingface_hub==2.4.0 via uvx.
#
# Persistence: everything lives under ~/workspace, which survives stop and
# is destroyed on delete. A systemd unit restarts the stack on every boot and
# refreshes the TURN address, because the public IP can change after start.
set -euo pipefail

BLUEPRINT_REPO="https://github.com/NVIDIA-AI-Blueprints/nemotron-voice-agent.git"
BLUEPRINT_TAG="v2.3.1"
BLUEPRINT_SHA="1f5bd71050d79d94890675800b20533178f28abe"
VOICE_PROFILE="${VOICE_PROFILE:-generic-assistant/single-gpu}"
HF_TOKEN="${HF_TOKEN:-}"

WS="$HOME/workspace"
APP="$WS/nemotron-voice-agent"
START="$WS/nemotron-voice-agent-start.sh"
UNIT="/etc/systemd/system/nemotron-voice-agent.service"
TOOLS="$WS/tools"
MODELS="$APP/models/nemo-speech"
COTURN_OVERRIDE="$WS/coturn-pin.override.yaml"
COTURN_IMAGE="instrumentisto/coturn:4.5.2@sha256:6c25f154177c9e9fccc3ba6f28455ad3b0a869f00be0562853a327b5f7b6069a"
UV_VERSION="0.13.8"
UV_SHA256="5acfd9177cfecf0bf87578f059728215ccc884388988f55f7a65041b57387d91"
HF_HUB_VERSION="2.4.0"
# Speech model files the blueprint's download script must leave behind
# (its own required set plus the VAD model the single-GPU profiles need).
SPEECH_FILES=(
  "nemotron-speech-streaming-en-0.6b.q8_0.gguf"
  "nemotron-3.5-asr-streaming-0.6b.q8_0.gguf"
  "magpie-tts/magpie_tts_multilingual_357m.v2607.f16.gguf"
  "nano-codec/nemo_nano_codec_22khz_1.89kbps_21.5fps.decoder.f16.gguf"
  "vad/silero-v6.2.0.gguf"
)

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this setup script as the instance's default user, not root" >&2
  exit 1
fi

case "$VOICE_PROFILE" in
  generic-assistant/single-gpu|multilingual-assistant/single-gpu) ;;
  *) echo "Unsupported VOICE_PROFILE: $VOICE_PROFILE" >&2; exit 1 ;;
esac
# App service name in the blueprint compose, e.g. generic-assistant-single-gpu.
APP_SERVICE="${VOICE_PROFILE%%/*}-single-gpu"

# Preconditions. The base image already provides the driver, Docker and the
# NVIDIA Container Toolkit; this script never reinstalls them.
command -v nvidia-smi >/dev/null || { echo "nvidia-smi not found" >&2; exit 1; }
DRIVER="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader --id=0)"
if [ "${DRIVER%%.*}" -lt 580 ]; then
  echo "NVIDIA driver $DRIVER found; the blueprint needs 580 or newer" >&2
  exit 1
fi
COMPOSE_VERSION="$(sudo docker compose version --short)"
COMPOSE_MAJOR="${COMPOSE_VERSION%%.*}"
COMPOSE_MINOR="$(echo "$COMPOSE_VERSION" | cut -d. -f2)"
if [ "$COMPOSE_MAJOR" -lt 2 ] || { [ "$COMPOSE_MAJOR" -eq 2 ] && [ "$COMPOSE_MINOR" -lt 20 ]; }; then
  echo "Docker Compose $COMPOSE_VERSION found; the blueprint needs 2.20 or newer" >&2
  exit 1
fi

mkdir -p "$WS" "$WS/huggingface" "$HOME/.cache"

# Hugging Face cache on the workspace disk (the blueprint mounts
# ~/.cache/huggingface into the vLLM container).
if [ ! -e "$HOME/.cache/huggingface" ]; then
  ln -s "$WS/huggingface" "$HOME/.cache/huggingface"
fi

# Blueprint source at the pinned tag, verified against the pinned commit.
if [ ! -d "$APP/.git" ]; then
  git clone --branch "$BLUEPRINT_TAG" --depth 1 "$BLUEPRINT_REPO" "$APP"
fi
if [ "$(git -C "$APP" rev-parse HEAD)" != "$BLUEPRINT_SHA" ]; then
  echo "Blueprint checkout is not commit $BLUEPRINT_SHA (tag $BLUEPRINT_TAG)" >&2
  exit 1
fi

# .env for the blueprint. The TURN password is generated once on this
# instance and never printed. HF_TOKEN is written only when supplied.
umask 077
ENV_FILE="$APP/.env"
if [ ! -f "$ENV_FILE" ]; then
  TURN_SECRET="$(openssl rand -hex 24)"
  cat > "$ENV_FILE" <<EOF
HF_TOKEN=${HF_TOKEN}
PIPELINE_TLS=false
TURN_URL=
TURN_USERNAME=voiceagent
TURN_PASSWORD=${TURN_SECRET}
EOF
  unset TURN_SECRET
elif [ -n "$HF_TOKEN" ]; then
  sed -i "/^HF_TOKEN=/d" "$ENV_FILE"
  cat >> "$ENV_FILE" <<EOF
HF_TOKEN=${HF_TOKEN}
EOF
fi
chmod 600 "$ENV_FILE"
umask 022

# uv (pinned release archive, checksum verified) for the model download script.
mkdir -p "$TOOLS/bin"
if [ ! -x "$TOOLS/bin/uv" ] || [ "$("$TOOLS/bin/uv" --version | cut -d' ' -f2)" != "$UV_VERSION" ]; then
  UV_TGZ="$TOOLS/uv-$UV_VERSION.tar.gz"
  curl -fsSL --retry 3 -o "$UV_TGZ" \
    "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz"
  if ! sha256sum -c --status <<<"$UV_SHA256  $UV_TGZ"; then
    echo "uv $UV_VERSION archive failed its SHA-256 check" >&2
    exit 1
  fi
  tar -xzf "$UV_TGZ" -C "$TOOLS/bin" --strip-components=1 \
    uv-x86_64-unknown-linux-gnu/uv uv-x86_64-unknown-linux-gnu/uvx
  rm -f "$UV_TGZ"
fi
# hf CLI pinned through uvx (the download script prefers "hf" on PATH).
cat > "$TOOLS/bin/hf" <<EOF
#!/bin/bash
exec "$TOOLS/bin/uvx" --from "huggingface_hub==$HF_HUB_VERSION" hf "\$@"
EOF
chmod 755 "$TOOLS/bin/hf"

speech_models_present() {
  local f
  for f in "${SPEECH_FILES[@]}"; do
    [ -s "$MODELS/$f" ] || return 1
  done
}

# Speech models: the blueprint's own script (docs/01-getting-started.md 4.3),
# run as this user from the repo root. The script reads the Hugging Face token
# from the mode-600 .env written above; it is never placed on a command line.
# Skipped when every expected file is already present (re-run, restart).
if ! speech_models_present; then
  mkdir -p "$MODELS"
  (
    cd "$APP"
    env PATH="$TOOLS/bin:$PATH" \
      UV_CACHE_DIR="$WS/.cache/uv" \
      UV_PYTHON_INSTALL_DIR="$TOOLS/python" \
      HF_HOME="$WS/huggingface" \
      bash scripts/download-nemo-speech-models.sh
  )
fi
if ! speech_models_present; then
  for f in "${SPEECH_FILES[@]}"; do
    [ -s "$MODELS/$f" ] || echo "Missing speech model file: models/nemo-speech/$f" >&2
  done
  exit 1
fi

# coturn pin: override the image of the blueprint's included "coturn" service.
cat > "$COTURN_OVERRIDE" <<EOF
services:
  coturn:
    image: $COTURN_IMAGE
EOF

# Boot script: refresh the TURN address to the current public IP, then
# start (or recreate) the stack. Runs as root from systemd with this user's HOME.
cat > "$START" <<EOF
#!/bin/bash
set -euo pipefail
export HOME="$HOME"
cd "$APP"
# Public IP lookup is best effort: on failure keep the TURN_URL already in .env.
IP="\$(curl -fsS --max-time 10 https://checkip.amazonaws.com || true)"
IP="\${IP//[[:space:]]/}"
if [[ "\$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\$ ]]; then
  sed -i "s#^TURN_URL=.*#TURN_URL=turn:\$IP:3478#" .env
else
  echo "Public IP lookup failed; keeping the existing TURN_URL" >&2
fi
# Upstream single-GPU invocation (docs/01-getting-started.md 4.3) plus the turn
# profile and the coturn digest pin override.
DC=(docker compose -f docker-compose.yml -f "$COTURN_OVERRIDE" --profile "$VOICE_PROFILE" --profile turn)
SERVICES="\$("\${DC[@]}" config --services)"
if ! grep -qx "$APP_SERVICE" <<<"\$SERVICES"; then
  echo "Compose profile $VOICE_PROFILE did not resolve service $APP_SERVICE" >&2
  exit 1
fi
IMAGES="\$("\${DC[@]}" config --images)"
if ! grep -qxF "$COTURN_IMAGE" <<<"\$IMAGES"; then
  echo "coturn image is not pinned to $COTURN_IMAGE" >&2
  exit 1
fi
"\${DC[@]}" up -d
EOF
chmod 755 "$START"

sudo tee "$UNIT" >/dev/null <<EOF
[Unit]
Description=Nemotron Voice Agent (Docker Compose)
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$START
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable nemotron-voice-agent.service

# First start: builds the app image and pulls the model servers. The speech
# models are already on disk; the LLM downloads inside vLLM after this returns.
sudo "$START"

# Health check: the voice app answers on port 7860. Model download and
# warm-up continue after this; the README explains the first-start wait.
# 180 tries x 20 s = 60 minutes, the blueprint's stated first-run upper bound.
for _ in $(seq 1 180); do
  if curl -fsS --max-time 5 http://localhost:7860/health >/dev/null; then
    echo "Nemotron Voice Agent app is up on port 7860; models load in the background."
    exit 0
  fi
  sleep 20
done
echo "Voice app did not answer on http://localhost:7860/health within 60 minutes" >&2
exit 1
