# Attributions and licences

| Component | Licence | Source |
| --- | --- | --- |
| GROMACS 2026.4 | GNU LGPL version 2.1 | https://gitlab.com/gromacs/gromacs (tag v2026.4, commit 6c69f720aa7378fddfee67f99d51aff21ccfb0a2); copy in the image, see below |
| FFTW 3.3.10 (built by the GROMACS build, GMX_BUILD_OWN_FFTW) | GNU GPL version 2 | https://www.fftw.org; copy in the image, see below |
| RDKit 2026.9.2 | BSD 3-Clause | https://github.com/rdkit/rdkit |
| Hermes Agent v0.23.2 | MIT | https://github.com/NousResearch/hermes-agent |
| vLLM v0.32.0 | Apache 2.0 | https://github.com/vllm-project/vllm |
| Open WebUI v0.13.3 | Open WebUI License (BSD 3-Clause based, branding clause) | https://github.com/open-webui/open-webui |
| NVIDIA Nemotron 3.5 Super VL (NVFP4) | OpenMDW License Agreement 1.1 | https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4 |
| LitmusBench v0.2 | CC BY-SA 4.0 for questions with ChEMBL data; OpenMDW 1.1 for all other questions | https://huggingface.co/datasets/nvidia/Nemotron-RL-litmus-bench-v0.2 |
| ChEMBL (data inside LitmusBench) | CC BY-SA 4.0 | https://www.ebi.ac.uk/chembl/ |
| Lysozyme structure 1AKI | RCSB PDB (wwPDB data are free of usage restrictions) | https://www.rcsb.org/structure/1AKI |

## Source for the GPL and LGPL components

The science tools image contains GROMACS, which is built with FFTW compiled into it. The complete corresponding source for both ships inside the same image, in the folder `/opt/science/src`:

- `gromacs-6c69f720aa7378fddfee67f99d51aff21ccfb0a2.tar.gz` - the GROMACS source at the exact commit that was built (tag v2026.4)
- `fftw-3.3.10.tar.gz` - the FFTW release tarball that was built
- `SHA256SUMS` - sha256 checksums of both files, checked when the image is built
- `README.txt` - what each file is

To copy the sources out on your instance:

```
cd /home/ubuntu/workspace
sudo docker compose cp science-tools:/opt/science/src ./science-tools-src
cd science-tools-src && sha256sum -c SHA256SUMS
```

If the science-tools container is not running, use the image directly:

```
id=$(sudo docker create IMAGE)
sudo docker cp "$id":/opt/science/src ./science-tools-src
sudo docker rm "$id"
```

where IMAGE is the science-tools image named in `compose.yaml`. `sudo docker compose exec science-tools gmx --version` prints the GROMACS build configuration. The same sources are also available from the upstream projects at the addresses above.

## Data handling

The LitmusBench file is downloaded on your instance from Hugging Face at a fixed revision; it is not redistributed. Benchmark results store question ids and scores only. The model weights are downloaded directly from Hugging Face.
