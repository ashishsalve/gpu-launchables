# Run the larger Nemotron 3.5 Bolt 74B model

The default model is Nemotron 3.5 Bolt E4B. The launch parameter `MODEL=74b` switches to [NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB-GGUF](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB-GGUF), a larger model that also ships a vision projector file.

## GPU

With `MODEL=74b` the model server starts only on a GPU that reports at least 40000 MiB of memory. When you set `MODEL=74b`, also pick such a GPU on the deploy page, for example an NVIDIA L40S 48GB.

If the GPU reports less than 40000 MiB, the model server does not start. It logs a message and waits, and the dashboard stays up. To fix it, delete the instance and deploy again with `MODEL=e4b`, or with `MODEL=74b` on a larger GPU.

## Download and disk

On first start llama.cpp downloads two files from a fixed Hugging Face revision:

- `NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB.gguf`, 22,018,326,528 bytes
- `mmproj-NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB.gguf`, 1,733,692,736 bytes

Both are stored under `/home/ubuntu/workspace/hermes-bolt/models` and are checked by size. Together they take 23,752,019,264 bytes of disk on top of the default model.

## Licence

The 74B model is governed by the OpenMDW License Agreement, version 1.1. Read the model card before use.
