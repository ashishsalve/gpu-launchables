#!/bin/bash
# Isaac Lab + Newton Robot Learning - setup script (runs once, as the default user).
# Installs Isaac Lab 3.0.0 in its kit-less mode (Newton physics, no Isaac Sim),
# registers a Jupyter kernel, writes a starter notebook, starts TensorBoard and
# ends with a short headless training run as a health check.
#
# Pins (uv and every package installed by name are fixed; other dependencies resolve at install time; change pins only together with a new test run):
# - uv 0.13.8: release of 2026-11-12, checksum from the release's .sha256 file.
# - isaaclab 3.0.0: Isaac Lab 3.0 release (PyPI upload 2026-10-19); it pins
#   torch 2.11.0 (CUDA 13.0 build), warp-lang 1.17.0, newton[sim] 1.6.1 and
#   rsl-rl-lib 5.5.1 itself.
# - Python 3.12: the only Python version isaaclab 3.0.0 supports (>=3.12,<3.13).
# - tensorboard 2.21.0 and ipykernel 7.4.0: current releases, pinned because
#   isaaclab does not pin them.
# - playground 1.0.1 (optional MuJoCo Playground): release of 2026-11-09; it
#   needs warp-lang 1.18, so it gets its own environment.
# - libegl1: Ubuntu archive package (not version-pinned); TensorBoard's open3d plugin loads libEGL.so.1.
set -euo pipefail

WS="$HOME/workspace"
LAB="$WS/isaaclab-newton"
PG="$WS/mujoco-playground"
BIN="$WS/.local/bin"
UV="$BIN/uv"
UV_VERSION="0.13.8"
UV_SHA256="5acfd9177cfecf0bf87578f059728215ccc884388988f55f7a65041b57387d91"
MIN_DRIVER="580.65.06"
EXTRA="${EXTRA_STACK:-none}"

export UV_CACHE_DIR="$WS/.cache/uv"
export UV_PYTHON_INSTALL_DIR="$WS/.local/python"
# The uv cache and the environments share one filesystem under $WS, so
# hardlinks keep a single copy of each package on disk (copy mode stored
# every package twice: once in the cache and once in the environment).
export UV_LINK_MODE="hardlink"

mkdir -p "$LAB/logs" "$LAB/notebooks" "$BIN" "$UV_CACHE_DIR" "$UV_PYTHON_INSTALL_DIR"

# 1. GPU and driver check (Isaac Lab 3.0 needs driver 580.65.06 or newer on Linux).
DRIVER="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)"
LOWEST="$(printf '%s\n%s\n' "$MIN_DRIVER" "$DRIVER" | sort -V | head -n 1)"
if [ "$LOWEST" != "$MIN_DRIVER" ]; then
  echo "NVIDIA driver $DRIVER is older than $MIN_DRIVER, which Isaac Lab 3.0 requires." >&2
  exit 1
fi
echo "NVIDIA driver $DRIVER ok"

# 2. uv, pinned release binary, checksum verified before use.
if [ ! -x "$UV" ] || ! "$UV" --version | grep -q " $UV_VERSION"; then
  TMP="$(mktemp -d)"
  curl -fsSL --retry 3 -o "$TMP/uv.tar.gz" \
    "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz"
  echo "$UV_SHA256  $TMP/uv.tar.gz" | sha256sum -c -
  tar -xzf "$TMP/uv.tar.gz" -C "$TMP"
  install -m 0755 "$TMP/uv-x86_64-unknown-linux-gnu/uv" "$UV"
  rm -rf "$TMP"
fi
"$UV" --version

# 3. Isaac Lab 3.0.0 (kit-less) with rsl_rl, the Viser visualizer, TensorBoard and a Jupyter kernel.
if [ ! -x "$LAB/.venv/bin/python" ]; then
  "$UV" venv --python 3.12 --seed "$LAB/.venv"
fi
"$UV" pip install --python="$LAB/.venv/bin/python" --extra-index-url https://pypi.nvidia.com --torch-backend=cu130 "isaaclab[rsl-rl,viser]==3.0.0" "tensorboard==2.21.0" "ipykernel==7.4.0"
"$LAB/.venv/bin/python" -m ipykernel install --user --name isaaclab-newton --display-name "Isaac Lab 3.0 (Newton)"

# 4. Optional: MuJoCo Playground in its own environment.
if [ "$EXTRA" = "mujoco-playground" ]; then
  mkdir -p "$PG"
  if [ ! -x "$PG/.venv/bin/python" ]; then
    "$UV" venv --python 3.12 --seed "$PG/.venv"
  fi
  "$UV" pip install --python="$PG/.venv/bin/python" --torch-backend=cu130 "playground[rl]==1.0.1" "ipykernel==7.4.0"
  "$PG/.venv/bin/python" -m ipykernel install --user --name mujoco-playground --display-name "MuJoCo Playground"
fi

# 5. Starter notebook (written once; your edits are kept on re-runs).
NB="$LAB/notebooks/train_with_newton.ipynb"
if [ ! -f "$NB" ]; then
  "$LAB/.venv/bin/python" - "$NB" "$LAB" <<'PY'
import json, sys
nb_path, lab = sys.argv[1], sys.argv[2]
def md(s): return {"cell_type": "markdown", "metadata": {}, "source": s}
def code(s): return {"cell_type": "code", "metadata": {}, "execution_count": None, "outputs": [], "source": s}
cells = [
    md("# Train a policy with Isaac Lab 3.0 and Newton\n\n"
       "This notebook runs Isaac Lab in its kit-less mode: Newton physics (MuJoCo Warp solver), "
       "no Isaac Sim, no display. Use the **Isaac Lab 3.0 (Newton)** kernel. "
       "Training logs go to `" + lab + "/logs`, which TensorBoard (port 6006) reads."),
    code("import os, sys\nBIN = os.path.dirname(sys.executable)  # the kernel's environment\n%cd " + lab + "\n!nvidia-smi"),
    md("## 1. Cartpole in a few minutes\n\nThe first run compiles GPU kernels, so it is slower than later runs."),
    code("!{BIN}/isaaclab train --rl_library rsl_rl --task Isaac-Cartpole-Direct --num_envs 4096 --max_iterations 150 physics=newton_mjwarp"),
    md("## 2. Locomotion\n\nList the registered locomotion tasks, then set `TASK` to one of them. "
       "The full task list is in the Isaac Lab documentation: https://isaac-sim.github.io/IsaacLab/"),
    code("import subprocess, sys\n"
         "out = subprocess.run([sys.executable, '-c', \"import gymnasium as gym, isaaclab_tasks; "
         "print(chr(10).join(sorted(k for k in gym.registry if 'Velocity' in k)))\"], capture_output=True, text=True)\n"
         "print(out.stdout or out.stderr)"),
    code("TASK = ''  # paste a locomotion task id from the list above\n"
         "assert TASK, 'set TASK first'\n"
         "!{BIN}/isaaclab train --rl_library rsl_rl --task {TASK} --max_iterations 300 physics=newton_mjwarp"),
    md("## 3. Replay the trained policy\n\nAdd `--viz viser` to watch it in the Viser browser viewer "
       "(see the Isaac Lab documentation for the visualizer options)."),
    code("!{BIN}/isaaclab play --task {TASK} --checkpoint latest physics=newton_mjwarp"),
]
nb = {"cells": cells, "metadata": {"kernelspec": {"name": "isaaclab-newton", "display_name": "Isaac Lab 3.0 (Newton)", "language": "python"}},
      "nbformat": 4, "nbformat_minor": 5}
with open(nb_path, "w") as f:
    json.dump(nb, f, indent=1)
PY
fi

# 6. TensorBoard as a service: starts on boot and after every stop/start.
# The open3d TensorBoard plugin installed in this environment loads libEGL.so.1;
# without it TensorBoard fails at import.
sudo apt-get -o DPkg::Lock::Timeout=600 update
sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 install -y --no-install-recommends libegl1
sudo tee /etc/systemd/system/isaaclab-tensorboard.service >/dev/null <<UNIT
[Unit]
Description=TensorBoard for Isaac Lab training logs
After=network-online.target
Wants=network-online.target

[Service]
User=$(id -un)
WorkingDirectory=$LAB
ExecStart=$LAB/.venv/bin/tensorboard --logdir $LAB/logs --host 0.0.0.0 --port 6006
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable --now isaaclab-tensorboard.service

# 7. Health check: GPU visible to PyTorch, a short headless Newton training run, TensorBoard up.
"$LAB/.venv/bin/python" -c "import torch; assert torch.cuda.is_available(); print('cuda ok', torch.cuda.get_device_name(0))"
cd "$LAB"
PATH="$LAB/.venv/bin:$PATH" isaaclab train --rl_library rsl_rl --task Isaac-Cartpole-Direct --num_envs 16 --max_iterations 5 physics=newton_mjwarp
if [ "$EXTRA" = "mujoco-playground" ]; then
  "$PG/.venv/bin/python" -c "import mujoco_playground; print('mujoco playground ok')"
fi
for _ in $(seq 1 30); do
  if curl -fsS --max-time 5 -o /dev/null http://localhost:6006/; then
    echo "isaaclab-newton ready"
    exit 0
  fi
  sleep 2
done
echo "TensorBoard did not answer on port 6006" >&2
exit 1
