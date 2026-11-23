<p align="center">
  <strong>Isaac Lab + Newton on NVIDIA Brev</strong><br>
  Train reinforcement learning policies for robots on one NVIDIA L40S: Isaac Lab 3.0 in kit-less mode on the Newton physics engine, with JupyterLab and TensorBoard.
</p>

# Isaac Lab + Newton Robot Learning

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8arIbDn5RySQJP1XtedUwZdFa)

Launchable ID: env-3M8arIbDn5RySQJP1XtedUwZdFa

Train reinforcement learning policies for robots on one GPU. [Isaac Lab](https://github.com/isaac-sim/IsaacLab) 3.0 runs in its kit-less mode on the [Newton](https://github.com/newton-physics/newton) physics engine: headless, with no Isaac Sim install. You get a JupyterLab notebook to start a training run, TensorBoard to watch it, and the `isaaclab` command line for everything else. [MuJoCo Playground](https://github.com/google-deepmind/mujoco_playground) is available as an option. First step: deploy, open the starter notebook in JupyterLab and train Cartpole.

| Quick facts | |
| --- | --- |
| Runs | Isaac Lab 3.0.0 (kit-less) on Newton 1.6.1 with PyTorch 2.11.0 and rsl_rl 5.5.1, JupyterLab kernel and TensorBoard; MuJoCo Playground optional; installed by `setup.sh` on a VM |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge, 4 vCPU, 32 GiB RAM), stoppable; you can pick another GPU on the deploy page |
| Disk | 150 GiB |
| Ready in | about 7 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | none; Isaac Lab, Newton and MuJoCo Playground need no token |
| Licences | Isaac Lab BSD-3-Clause, Newton Apache-2.0, MuJoCo Playground Apache-2.0 |
| Guide | https://www.9owls.com/launchables/isaac-lab-newton/ |

Current versions: Isaac Lab 3.0.0, Newton 1.6.1, PyTorch 2.11.0 (CUDA 13.0), rsl_rl 5.5.1, MuJoCo Playground 1.0.1 (optional)

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

## Contents

- [What you get](#what-you-get)
- [Deploy in three steps](#deploy-in-three-steps)
- [Try it first](#try-it-first)
- [How it works](#how-it-works)
- [Settings](#settings)
- [Use it from your machine](#use-it-from-your-machine)
- [Data and persistence](#data-and-persistence)
- [Stop, start and delete](#stop-start-and-delete)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Installed from |
| --- | --- | --- |
| Isaac Lab (kit-less, `isaaclab[rsl-rl,viser]`) | 3.0.0 | PyPI |
| Newton physics (MuJoCo Warp solver) | 1.6.1 (pinned by Isaac Lab) | PyPI |
| PyTorch (CUDA 13.0 build) and rsl_rl | 2.11.0 and 5.5.1 (pinned by Isaac Lab) | PyPI |
| TensorBoard | 2.21.0 | PyPI |
| MuJoCo Playground (`playground[rl]`, optional) | 1.0.1 | PyPI |
| uv (Python environment manager) | 0.13.8 | GitHub release, checksum verified |
| Starter notebook | `train_with_newton.ipynb` | written by `setup.sh` |

Isaac Sim is not installed. Features that need Isaac Sim, such as the Kit viewport and RTX rendering, are not part of this environment.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, leave `EXTRA_STACK` at `none` unless you want MuJoCo Playground, and deploy.
2. Wait until the instance shows Running and setup has finished. On a fresh deploy this took about 7 minutes; `setup.sh` ends with a short headless Cartpole training run as a health check.
3. Open JupyterLab, open `~/workspace/isaaclab-newton/notebooks/train_with_newton.ipynb` and select the **Isaac Lab 3.0 (Newton)** kernel.

## Try it first

1. Train Cartpole: run the first cells of the starter notebook. The Cartpole cell trains `Isaac-Cartpole-Direct` with 4096 environments for 150 iterations on Newton. The first run compiles GPU kernels, so it is slower than later runs.
2. Watch it learn: open the **tensorboard** link to follow rewards and losses while training runs.
3. Train a locomotion policy: run the notebook cell that lists the registered locomotion tasks, set `TASK` to one of them (for example `Isaac-Velocity-Flat-AnymalD`), and run the training cell. The last cell replays the trained policy.

From a terminal on the instance, the same commands work directly:

```
cd ~/workspace/isaaclab-newton
.venv/bin/isaaclab train --rl_library rsl_rl --task Isaac-Cartpole-Direct physics=newton_mjwarp
.venv/bin/isaaclab play --task Isaac-Cartpole-Direct --checkpoint latest physics=newton_mjwarp
```

## How it works

- This Launchable runs on a VM. `setup.sh` runs once when the instance is created. It installs everything into Python 3.12 environments under `~/workspace`, registers the Jupyter kernels, writes the starter notebook, starts TensorBoard as a service and finishes with a short headless Cartpole training run as a health check.
- `setup.sh` first checks the NVIDIA driver and stops with a clear message if it is older than 580.65.06, as Isaac Lab 3.0 requires.
- JupyterLab is the entry point. The **Isaac Lab 3.0 (Newton)** kernel runs from `~/workspace/isaaclab-newton/.venv`.
- TensorBoard runs as the systemd service `isaaclab-tensorboard` on port 6006, reads `~/workspace/isaaclab-newton/logs` and is reached through the **tensorboard** link.
- Training is headless: simulation and policy learning run on the GPU with Newton's MuJoCo Warp solver (`physics=newton_mjwarp`), with no display.
- There are no secrets. The instance downloads the pinned packages from PyPI and the uv release from GitHub during setup.

<details>
<summary>Advanced: what is pinned</summary>

The uv binary and every package `setup.sh` installs by name are pinned (Isaac Lab in turn pins PyTorch, Warp, Newton and rsl_rl); their remaining dependencies and the libegl1 system library resolve at deploy time. MuJoCo Playground needs a newer Warp than Isaac Lab 3.0 pins, so it gets its own environment.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `EXTRA_STACK` | no | `none` | `none` installs Isaac Lab with Newton only. `mujoco-playground` also installs MuJoCo Playground 1.0.1 in its own environment (`~/workspace/mujoco-playground/.venv`) with a **MuJoCo Playground** Jupyter kernel, which adds about 10 minutes of setup. |

See the MuJoCo Playground [documentation](https://github.com/google-deepmind/mujoco_playground) for its training commands.

## Use it from your machine

To reach TensorBoard from your own machine without the link, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 6006:6006
```

Then open http://localhost:6006 locally to see the training curves.

## Data and persistence

Everything lives under `~/workspace` on the instance, which is `/home/ubuntu/workspace`:

- Isaac Lab environment: `/home/ubuntu/workspace/isaaclab-newton/.venv`
- Training logs and checkpoints: `/home/ubuntu/workspace/isaaclab-newton/logs`
- Starter notebook: `/home/ubuntu/workspace/isaaclab-newton/notebooks`
- Optional MuJoCo Playground environment: `/home/ubuntu/workspace/mujoco-playground/.venv`

They survive a stop and start of the instance. They are removed when the instance is deleted. Copy checkpoints you want to keep off the instance before deleting it.

## Stop, start and delete

- **Stop** the instance when you are not training. Your environments, logs and checkpoints are kept, and TensorBoard starts again on the next start. Storage is still billed while the instance is stopped.
- **Start** it again: TensorBoard and the Jupyter kernel come back by themselves, with nothing to re-enter. `setup.sh` does not run again.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including trained checkpoints.

## Troubleshooting

<details>
<summary>Setup stops with a driver message</summary>

`setup.sh` stops with "NVIDIA driver ... is older than 580.65.06, which Isaac Lab 3.0 requires." if the GPU you picked has an older driver. Delete the instance and deploy again on the default NVIDIA L40S or another GPU type with a newer driver.

</details>

<details>
<summary>The tensorboard link does not load after a start</summary>

TensorBoard runs as a systemd service that starts by itself and restarts if it stops. Check and restart it from a terminal on the instance:

```
sudo systemctl status isaaclab-tensorboard
sudo systemctl restart isaaclab-tensorboard
```

</details>

<details>
<summary>The first training run is slow to start</summary>

The first run compiles GPU kernels, so it is slower than later runs. Wait for the iteration log to appear.

</details>

<details>
<summary>The locomotion cell fails with "set TASK first"</summary>

Run the cell that lists the registered locomotion tasks, paste one task id into `TASK` (for example `Isaac-Velocity-Flat-AnymalD`), then run the training cell again.

</details>

## FAQ

### Which GPU do I need?

One NVIDIA GPU with driver 580.65.06 or newer, as Isaac Lab 3.0 requires. The default is one NVIDIA L40S 48GB with 150 GiB of disk.

### Do I need Isaac Sim?

No. Isaac Lab 3.0 runs here in its kit-less mode on the Newton physics engine. Features that need Isaac Sim, such as the Kit viewport and RTX rendering, are not part of this environment.

### Where do my checkpoints live?

Under `/home/ubuntu/workspace/isaaclab-newton/logs`. They survive Stop and are removed by Delete, so copy the ones you want to keep off the instance first.

### Does anything leave the instance?

Training runs on the instance. During setup the instance downloads the pinned packages from PyPI and the uv release from GitHub. No token or account is needed.

### Can I run this on my own hardware?

Yes. `setup.sh` in this folder is the whole installation and runs on a Linux machine with an NVIDIA GPU and driver 580.65.06 or newer. See the [Isaac Lab](https://github.com/isaac-sim/IsaacLab) project for its installation guide.

### How do I update to a newer version?

This Launchable pins Isaac Lab 3.0.0 so every deploy is the same. To try a newer release on your own instance, install it into a new environment under `~/workspace` with uv; your logs and checkpoints are kept.

## Guides and related Launchables

- Step-by-step guide: [How to train a robot policy with Isaac Lab and Newton](https://www.9owls.com/guides/train-a-robot-policy-with-isaac-lab-and-newton/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/isaac-lab-newton/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Cosmos 3 Nano World Model Studio](https://www.9owls.com/launchables/cosmos3-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aVI8A9ooLqzhwIEkWuuY27Pm)); [RAPIDS Data Science with cuDF and cuML](https://www.9owls.com/launchables/rapids-datascience/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aZ3FqwckUgj9tV7qQc9B3vVG)); [LoRA Training (ai-toolkit + kohya_ss)](https://www.9owls.com/launchables/lora-training/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M77hJCDpHkAGNvOR4xmmgsC1KA))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [Isaac Lab](https://github.com/isaac-sim/IsaacLab): BSD-3-Clause (the isaaclab_mimic extension is Apache-2.0).
- [Newton](https://github.com/newton-physics/newton), installed as an Isaac Lab dependency: Apache-2.0.
- [MuJoCo Playground](https://github.com/google-deepmind/mujoco_playground), optional: Apache-2.0.
- [uv](https://github.com/astral-sh/uv): Apache-2.0 or MIT.
- PyTorch, NVIDIA Warp, rsl_rl, TensorBoard, ipykernel and their dependencies: each under its own licence.

Files in this folder: `setup.sh` (the setup script, every package it installs by name pinned) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
