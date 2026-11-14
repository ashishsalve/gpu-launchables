# ComfyUI Pro - the audited custom-node set

ComfyUI Pro ships exactly the node packs below, each checked out at one full git commit and baked into the container image (`ghcr.io/ashishsalve/comfyui-pro:0.45.0@sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef`). Nothing is installed from the Comfy Registry or from ComfyUI-Manager's catalog at deploy time. ComfyUI-Manager starts at `security_level = strong`.

Why this matters: malicious custom nodes published to the Comfy Registry ("Upscaler_4K" and look-alikes) delivered an information stealer to about 779 installs (ComfyUI issue #11791, https://github.com/comfyanonymous/ComfyUI/issues/11791). A pinned list means the code you run is the code that was reviewed.

## What "audited" means here (review of 2026-11-14)

For every pack:

1. Source is the author's own GitHub repository, not a registry upload or a fork.
2. Pinned to a full 40-character commit (the release tag's commit where the pack tags releases, otherwise the default branch head on 2026-11-14).
3. Repository is not archived; licence recorded.
4. `requirements.txt` read at the pinned commit; no `git+` or URL requirements.
5. Install hooks: none of the 12 packs has a root `install.py`, and the image never runs `install.py`, `install.sh` or any other installer a pack ships. The `prestartup_script.py` files of rgthree-comfy and ComfyUI-Easy-Use were read and only register paths.
6. The image installs requirements under a constraints file, so no pack can replace the image's PyTorch build.

Still pending: a line-by-line read of each pack's Python code at its pinned commit, and the first fresh-deploy smoke test. Both are recorded in the "Last smoke" line of the README when done.

## The set (12 packs)

| Pack | Author repository | Commit | Commit date | Licence | Notes |
|---|---|---|---|---|---|
| ComfyUI-KJNodes | https://github.com/kijai/ComfyUI-KJNodes | 56781c108c520e9c75db140b6886927c1785e3d2 | 2026-11-14 | GPL-3.0 | general utility nodes; no tags upstream |
| rgthree-comfy | https://github.com/rgthree/rgthree-comfy | bc48c6aaeca87bedbc14245d89f9bc6be37a630e | 2026-10-30 | MIT | workflow quality-of-life nodes; empty requirements |
| ComfyUI-Custom-Scripts | https://github.com/pythongosssss/ComfyUI-Custom-Scripts | 609f3afaa74b2f88ef9ce8d939626065e3247469 | 2026-02-12 | MIT | UI helpers; no requirements |
| ComfyUI-VideoHelperSuite | https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite | 4d907bee61e92c2e65af3bd6383a4e4d356126d1 | 2026-09-02 | GPL-3.0 | video load and combine |
| comfyui_controlnet_aux | https://github.com/Fannovel16/comfyui_controlnet_aux | b9abafa1019e230ebd674e4ae93f11bdf9d8dfc2 | 2026-11-14 | Apache-2.0 | ControlNet preprocessors; downloads preprocessor weights from Hugging Face on first use |
| ComfyUI-Advanced-ControlNet | https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet | 27a67fee80cf46c198b10588a5651f23d67d1e95 | 2026-07-28 | GPL-3.0 | ControlNet scheduling; no requirements |
| ComfyUI-GGUF | https://github.com/city96/ComfyUI-GGUF | 6ea2651e7df66d7585f6ffee804b20e92fb38b8a | 2026-01-12 | Apache-2.0 | GGUF-quantised model loading |
| ComfyUI_UltimateSDUpscale | https://github.com/ssitu/ComfyUI_UltimateSDUpscale | a5547db9e1d07d3318bb21e9e9c474f4c1e9c8df | 2026-06-22 | GPL-3.0 | tiled upscaling; its one submodule is pinned by this commit |
| ComfyUI-Easy-Use | https://github.com/yolain/ComfyUI-Easy-Use | 271685698b0935c5b0ecca86a58c3817931cd205 | 2026-09-04 | GPL-3.0 | release v1.4.1; its frontend submodule is pinned by this commit |
| cg-use-everywhere | https://github.com/chrisgoringe/cg-use-everywhere | ffc99037eea8eac4d4ad20bb72a12a87740279a9 | 2026-11-01 | Apache-2.0 | wireless node links; no requirements |
| ComfyUI-Crystools | https://github.com/crystian/ComfyUI-Crystools | 624bcccfa1c2d4746db11d0ee970f89b92e66caa | 2025-07-27 | MIT | release 1.26.0; GPU and VRAM monitor in the UI |
| ComfyUI-Florence2 | https://github.com/kijai/ComfyUI-Florence2 | 9ece3de914214c5f581d725167bc9d0eeb0d1120 | 2026-05-06 | MIT | captioning and detection; downloads Florence-2 weights on first use |

ComfyUI itself is v0.45.0 (commit 989d93d0d968e704c589ce0146bb18c77f6b50cc, GPL-3.0). ComfyUI-Manager is the `comfyui_manager==4.2.2` package that ComfyUI v0.45.0 pins in its `manager_requirements.txt` (GPL-3.0).

## Considered and left out (2026-11-14)

| Pack | Reason |
|---|---|
| ComfyUI-Impact-Pack | requirements install `sam2` from an unpinned `git+` URL |
| ComfyUI-Impact-Subpack | AGPL-3.0, pulls an unpinned `ultralytics` |
| ComfyUI-Inspire-Pack | depends on Impact-Pack; last release 2025-07 |
| ComfyUI_essentials | upstream in maintenance mode since 2025-04 |
| ComfyUI-RMBG | head commit is a web upload; installs both `onnxruntime` and `onnxruntime-gpu` |
| ComfyUI-Detail-Daemon | repository root carries an unexplained `node.zip` binary |

## Adding your own nodes

You can install more nodes after deploy by lowering the Manager's security level in `/home/ubuntu/workspace/comfyui-pro/user/__manager/config.ini` on the instance (the file is owned by root, so edit it with `sudo`; inside the container it is `/root/workspace/user/__manager/config.ini`) and restarting with `docker restart comfyui-pro`. Nodes you add are installed inside the container: they survive Stop and restarts, but not a re-created container. Anything you add is outside this audited set and is your responsibility; check the author and the code first.
