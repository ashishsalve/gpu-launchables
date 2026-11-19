# Tasks

Open the **open-code-server** link. The terminal starts inside the `kernel-lab` sandbox with the agent. Each task lives in `/sandbox/kernel-lab/tasks`. Ask the agent in plain language, for example the prompts below.

## 1. Fuse RMSNorm, scale and residual add

Folder: `01-fused-op`. `baseline.py` runs three eager PyTorch kernels.

Prompt: "Write one fused kernel for rmsnorm_scale_residual in 01-fused-op, make test_fused.py pass with KERNEL_CANDIDATE set, run compute-sanitizer memcheck, benchmark it with bench.py and add the result to the report."

Done when:
- `pytest -q test_fused.py` passes (atol 1e-3, fp16).
- `compute-sanitizer --tool memcheck` reports 0 errors.
- `python bench.py --candidate <module:function>` prints baseline_ms, kernel_ms and speedup_measured. It exits with code 3 and times nothing if another process keeps the GPU above 5 percent utilization.

## 2. Fix a shared-memory reduction

Folder: `02-reduce-bug`. `naive/reduce.cu` has two planted bugs.

Prompt: "Use compute-sanitizer to find and fix the bugs in 02-reduce-bug/naive/reduce.cu until test_reduce.py passes."

Done when `pytest -q test_reduce.py` passes: the sum is correct, and memcheck then racecheck both report `ERROR SUMMARY: 0 errors`.

## 3. Port NumPy pairwise distance to the GPU

Folder: `03-port-numpy`. `cpu/pairwise_dist.py` is a NumPy loop.

Prompt: "Profile cpu/pairwise_dist.py with nsys, port it to the GPU, prove it matches the NumPy reference with test_pairwise.py, and profile again."

Done when `pytest -q test_pairwise.py` passes with KERNEL_CANDIDATE set and both Nsight Systems reports are attached to the report row.

## Reading the Kernel Report

Open the **open-kernel-report** link. Each row comes from one result file in `/home/ubuntu/workspace/kernel-lab/results`. Speedup is baseline time divided by kernel time, measured on this GPU.
