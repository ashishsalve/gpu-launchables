# Isaac Lab + Newton Robot Learning

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8arIbDn5RySQJP1XtedUwZdFa)

Launchable ID: env-3M8arIbDn5RySQJP1XtedUwZdFa

Train reinforcement learning policies for robots on one GPU. [Isaac Lab](https://github.com/isaac-sim/IsaacLab) 3.0 runs in its kit-less mode on the [Newton](https://github.com/newton-physics/newton) physics engine: headless, with no Isaac Sim install. You get a JupyterLab notebook to start a training run, TensorBoard to watch it, and the `isaaclab` command line for everything else. [MuJoCo Playground](https://github.com/google-deepmind/mujoco_playground) is available as an option.

Current versions: Isaac Lab 3.0.0, Newton 1.6.1, PyTorch 2.11.0 (CUDA 13.0), rsl_rl 5.5.1, MuJoCo Playground 1.0.1 (optional)

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

## What it runs

| Component | Version | Installed from |
| --- | --- | --- |
| Isaac Lab (kit-less, `isaaclab[rsl-rl,viser]`) | 3.0.0 | PyPI |
| Newton physics (MuJoCo Warp solver) | 1.6.1 (pinned by Isaac Lab) | PyPI |
| TensorBoard | 2.21.0 | PyPI |
| MuJoCo Playground (`playground[rl]`, optional) | 1.0.1 | PyPI |
| uv (Python environment manager) | 0.13.8 | GitHub release, checksum verified |

`setup.sh` runs once when the instance is created. It installs everything into Python 3.12 environments under `~/workspace`, registers the Jupyter kernels, writes a starter notebook, starts TensorBoard as a service and finishes with a short headless Cartpole training run as a health check.

Isaac Sim is not installed. Features that need Isaac Sim, such as the Kit viewport and RTX rendering, are not part of this environment.

## Requirements

- NVIDIA GPU: default 1x L40S 48GB.
- NVIDIA driver 580.65.06 or newer, as Isaac Lab 3.0 requires. `setup.sh` checks this first and stops with a clear message if the driver is older.
- 150 GiB disk for the Python environments, the package cache and training logs.

## Options

| Parameter | Values | Default |
| --- | --- | --- |
| `EXTRA_STACK` | `none`, `mujoco-playground` | `none` |

Pick `mujoco-playground` to also install MuJoCo Playground 1.0.1 in its own environment (`~/workspace/mujoco-playground/.venv`) with a **MuJoCo Playground** Jupyter kernel. See its [documentation](https://github.com/google-deepmind/mujoco_playground) for training commands.

## Use it

1. Deploy and wait until the instance is Running and setup has finished.
2. Open JupyterLab and open `~/workspace/isaaclab-newton/notebooks/train_with_newton.ipynb`. Select the **Isaac Lab 3.0 (Newton)** kernel.
3. Run the Cartpole cell, then pick a locomotion task and train it.
4. Open the tensorboard link to follow rewards and losses while training runs.

From a terminal on the instance, the same commands work directly:

```
cd ~/workspace/isaaclab-newton
.venv/bin/isaaclab train --rl_library rsl_rl --task Isaac-Cartpole-Direct physics=newton_mjwarp
.venv/bin/isaaclab play --task Isaac-Cartpole-Direct --checkpoint latest physics=newton_mjwarp
```

To reach TensorBoard from your own machine without the link, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 6006:6006
```

## How data persists

Everything lives under `~/workspace` on the instance:

- Isaac Lab environment: `~/workspace/isaaclab-newton/.venv`
- Training logs and checkpoints: `~/workspace/isaaclab-newton/logs`
- Starter notebook: `~/workspace/isaaclab-newton/notebooks`

They survive a stop and start of the instance. They are removed when the instance is deleted. Copy checkpoints you want to keep off the instance before deleting it.

## Stop or delete to control cost

- **Stop** the instance when you are not training. Your environments, logs and checkpoints are kept, and TensorBoard starts again on the next start. Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including trained checkpoints.

## Files

- `setup.sh` - the setup script. The uv binary and every package it installs by name are pinned (Isaac Lab in turn pins PyTorch, Warp, Newton and rsl_rl); their remaining dependencies and the libegl1 system library resolve at deploy time.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
