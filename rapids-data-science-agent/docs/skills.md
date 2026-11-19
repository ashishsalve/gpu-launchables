# Skills

Hermes Agent loads skills from `workspace/hermes/skills/` (host path `/home/ubuntu/workspace/rapids-data-science-agent/hermes/skills/`). This Launchable installs an explicit list; nothing else is fetched.

## NVIDIA Agent Skills

Installed from the NVIDIA/skills repository at commit e8f43c17b6ed0e8888ad21a447f63b0617849f71, after a checksum check:

| Skill | Use |
| --- | --- |
| accelerated-computing-cudf | GPU dataframes with cuDF and cudf.pandas |
| cuml | GPU machine learning with cuML and cuml.accel |
| nvidia-skill-finder | Finding the right NVIDIA skill for a task |

## Bundled skills

Shipped inside `compose.yaml` (Apache-2.0):

| Skill | Use |
| --- | --- |
| polars-gpu-engine | Polars queries on the GPU with the cuDF-Polars engine, with a CPU comparison and a fallback check |
| cugraph-analytics | PageRank, Louvain and shortest paths with cuGraph, or NetworkX with the cuGraph backend |

## Add your own skill

Create a folder with a `SKILL.md` under `workspace/hermes/skills/`, for example `workspace/hermes/skills/my-skill/SKILL.md`, then restart the agent session. Bundled skills are copied again at every start, so edit a copy under a new name rather than the bundled files.
