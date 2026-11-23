<p align="center">
  <strong>Nemotron Parse Document Agent on NVIDIA Brev</strong><br>
  Turn PDFs and scans into cited answers and JSON with NVIDIA Nemotron Parse, Nemotron Embed and Nemotron 3 Nano Omni, served by vLLM on one NVIDIA L40S GPU.
</p>

# Nemotron Parse Document Agent

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MKGRFFpCaHD0VuHHnt6q5IbB65)

Launchable ID: env-3MKGRFFpCaHD0VuHHnt6q5IbB65

Turn PDFs and scans into cited answers and JSON on your own GPU. [NVIDIA Nemotron Parse](https://huggingface.co/nvidia/NVIDIA-Nemotron-Parse-2.0) reads each page of a document of up to 200 pages and maps its layout into text, tables and titles with bounding boxes. [NVIDIA Nemotron Embed](https://huggingface.co/nvidia/Nemotron-3.5-Embed-1B-BF16) indexes those blocks for search, and [NVIDIA Nemotron 3 Nano Omni](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4) answers questions and fills JSON fields, citing the page and block behind every claim. All three models are served by [vLLM](https://github.com/vllm-project/vllm) on one NVIDIA L40S; no document leaves the instance. Click Launch on Brev, and about 30 minutes later open the `open-doc-agent` link and load a sample document.

| Quick facts | |
| --- | --- |
| Runs | Nemotron Parse + Nemotron Embed + Nemotron 3 Nano Omni on three vLLM servers + a Python web app (Docker Compose) |
| Default compute | 1x NVIDIA L40S 48GB on AWS; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 30 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.26/hr on the default compute including 200 GiB storage (console, 2026-11-19); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token) |
| Licences | Nemotron 3 Nano Omni: NVIDIA Open Model Agreement; Nemotron Parse and Nemotron Embed: see their model cards; vLLM, pypdfium2 and Pillow: their own open-source licences; this folder: Apache-2.0 |
| Guide | https://www.9owls.com/launchables/nemotron-parse-document-agent/ |

1x L40S 48GB, >= 48 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~30 min to ready | Stop to pause, Delete when done

Current versions: vLLM v0.33.0 (image pinned by digest), NVIDIA-Nemotron-Parse-2.0 at revision 4e021c03edc92e715d5d788921a927d0cbb4b4d1, Nemotron-3.5-Embed-1B-BF16 at revision e24ca1e346bcc53572bd7bdc02b3e8ebf66c197c, Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4 at revision 16993199e436da4ba75ddc410855f87e0d996ee6, Python 3.12.12, pypdfium2 5.15.2, Pillow 13.0.0

Last smoke: 2026-11-19 (fresh deploy on 1x L40S).

## Contents

- [What you get](#what-you-get)
- [Deploy in three steps](#deploy-in-three-steps)
- [Try it first](#try-it-first)
- [Sample documents](#sample-documents)
- [How it works](#how-it-works)
- [Settings](#settings)
- [Use it from your machine](#use-it-from-your-machine)
- [Data and persistence](#data-and-persistence)
- [Stop, start and delete](#stop-start-and-delete)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Acceptable use and safety](#acceptable-use-and-safety)
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| vLLM OpenAI-compatible server | v0.33.0 (pinned by digest) | `vllm/vllm-openai:v0.33.0` |
| NVIDIA Nemotron Parse | revision 4e021c03edc92e715d5d788921a927d0cbb4b4d1 | `nvidia/NVIDIA-Nemotron-Parse-2.0` |
| NVIDIA Nemotron Embed | revision e24ca1e346bcc53572bd7bdc02b3e8ebf66c197c | `nvidia/Nemotron-3.5-Embed-1B-BF16` |
| NVIDIA Nemotron 3 Nano Omni | revision 16993199e436da4ba75ddc410855f87e0d996ee6 | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4` |
| Document app (Python) | Python 3.12.12, pypdfium2 5.15.2, Pillow 13.0.0 | inline in `compose.yaml` |

One web app behind the `open-doc-agent` link, with four views:

- **Documents** - three sample buttons and an upload box for PDF, PNG or JPEG files up to 200 MB. A PDF with more than 200 pages is refused with a message asking you to split it.
- **Pages** - every page as a thumbnail with the layout blocks Nemotron Parse found drawn on it.
- **Ask** - a question in plain words returns an answer split into claims. Each claim carries a chip such as `p.3 Table`: green when the quote it cites was found in that block, amber with the reason when it was not. Click a chip to highlight the block on its page.
- **Extract** - pick a form preset and get JSON in which every field has a value, page, box and a verified flag. A field is marked verified only when its value is copied word for word from the cited block. Verified (green) means the cited quote appears on the cited page of the source; it does not prove that the extracted value belongs in that field, so check each green field against the form.

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU with room for all three models, optionally set `HF_TOKEN`, and deploy.
2. Wait until the instance shows Running and the `open-doc-agent` link answers. A fresh deploy took about 30 minutes, most of it pulling the images and downloading the three models; the app's status bar shows which services are up.
3. Click `open-doc-agent`, press a sample button on the Documents view, and wait until the document shows as ready.

## Try it first

1. Load the Financial Report executive summary and ask: "Make a table of the government's net cost, net operating cost and budget deficit for FY 2025, with a citation for each figure."
2. Load IRS Form W-9, open Extract and run the `IRS Form W-9 layout` preset.
3. Load GSA Standard Form 1449, open Extract and run the `Contract form review` preset.

Click each chip to see the block it cites, and check green fields against the page before you rely on them.

## Sample documents

The sample buttons load three public U.S. Government documents:

| Button | Source | Pages |
| --- | --- | --- |
| Financial Report of the U.S. Government, FY 2025 executive summary | [fiscal.treasury.gov](https://fiscal.treasury.gov/system/files/2026-03/executive-summary-2025.pdf) | 11 |
| IRS Form W-9 | [irs.gov](https://www.irs.gov/pub/irs-prior/fw9--2024.pdf) | 6 |
| GSA Standard Form 1449 | [gsa.gov](https://www.gsa.gov/system/files/SF1449-21.pdf) | 2 |

The documents are not stored in this repository. The app downloads each one from its source on first use and refuses it if its size or SHA-256 checksum does not match the value pinned in `compose.yaml`.

## How it works

| Service | What it does | Where it listens |
| --- | --- | --- |
| `vllm-parse` | Nemotron Parse, one page image in, layout blocks out | localhost:8001 |
| `vllm-embed` | Nemotron Embed, vectors for search | localhost:8002 |
| `vllm-omni` | Nemotron 3 Nano Omni, answers and JSON with tool calls | localhost:8000 |
| `app` | Python web app: ingest, hybrid search (SQLite FTS5 plus vectors), agent loop and citation check | port 8080, the `open-doc-agent` Secure Link |

- The Launchable defines one Brev Secure Link, `open-doc-agent`, for port 8080. The three model servers listen on the instance loopback only.
- The three vLLM servers start one after another and share the GPU: 12, 10 and 66 percent of its memory.
- Ingest renders each PDF page to an image, sends it to Nemotron Parse, splits the blocks into chunks and indexes them.
- A question runs a short agent loop: Nemotron 3 Nano Omni may search again or look at a page image, then answers in a fixed JSON schema.
- All four services run under Docker Compose with the `unless-stopped` restart policy. All three models run on the instance, so no hosted model API key is set.

<details>
<summary>Advanced: how the citation check works</summary>

For a question that asks for figures, the closest-matching table blocks are always shown to the model. The citation check marks a claim verified only when the cited block was retrieved, the quote matches that block, every number in the claim appears in it and, when the page's PDF text layer holds that block, the quote is also in the text layer.

If a quote was copied from a different block than the one cited, the claim is re-cited to the block that holds the quote and passes the same check there, and the answer records the original citation. If a claim's number is missing from the block it cites but a table block shown to the model prints it, the claim is re-cited to that table row, and the answer records the original quote.

For a question that asks for figures, every claim must state its number. A year such as 2025 does not count as a figure.

In Extract, a field that a preset ties to the form page must cite a block on that page. If a claim or field fails, the model gets one retry with the reasons and the list of blocks it may cite; an Extract retry also gets the blocks found by searching for each failed field. Two Extract fields that hold the same value both fail, because the check cannot tell which one is right.

The app runs these checks against fixed test cases each time it starts (`python /data/app/app.py --selftest`) and does not start if any case fails.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `OMNI_MODEL` | no | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4` | The model that answers and extracts. |
| `HF_TOKEN` | no | none | Optional Hugging Face read token; raises download rate limits. Choose "Use a secret" to bind a saved secret (the option may be off for your account) or paste a read token. |

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The Nemotron 3 Nano Omni OpenAI-compatible API then answers on `http://localhost:8000/v1`. Use ports 8001 and 8002 the same way for Nemotron Parse and Nemotron Embed.

## Data and persistence

Everything lives under `/home/ubuntu/workspace` on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- Documents, page images and the search index: `/home/ubuntu/workspace/doc-agent/docs` and `/home/ubuntu/workspace/doc-agent/index.db`
- App packages: `/home/ubuntu/workspace/doc-agent/pip`

They survive a stop and start. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Models, documents and the index are kept. Storage is still billed while stopped.
- **Start** it again from the Brev console. The services use the `unless-stopped` restart policy and read models and documents from the workspace folders above. If the services are not back a few minutes after a start, run `cd /home/ubuntu/workspace && sudo docker compose up -d`.
- **Delete** the instance when you are finished. This removes it and all of its data.

## Troubleshooting

<details>
<summary>The app answers but a service is not up yet</summary>

The first start downloads three models, and the model servers start one after another. The app page shows which services are up in its status bar.

</details>

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service logs: `cd /home/ubuntu/workspace && sudo docker compose logs --no-color`

</details>

<details>
<summary>The services are not back after a start</summary>

Run `cd /home/ubuntu/workspace && sudo docker compose up -d`.

</details>

<details>
<summary>A sample button fails</summary>

The app refuses a sample whose size or SHA-256 checksum does not match the value pinned in `compose.yaml`, for example if the publisher re-issued the file. Upload your own PDF, PNG or JPEG instead.

</details>

<details>
<summary>An upload is refused</summary>

Uploads are limited to PDF, PNG or JPEG files up to 200 MB, and a PDF may have at most 200 pages. Split a longer PDF and upload the parts.

</details>

## FAQ

### Which GPU do I need for Nemotron Parse Document Agent?

Default compute: 1x NVIDIA L40S 48 GB, 200 GiB disk. This is the GPU used in the last smoke. You can pick other compute on the deploy page, but all three models must fit in GPU memory together.

### Does anything leave the instance?

No document leaves the instance: Nemotron Parse, Nemotron Embed and Nemotron 3 Nano Omni all run on its GPU, and no hosted model API key is set. The instance does download the models from Hugging Face and the sample documents from their publishers.

### What does a green chip mean?

Green means the cited quote was found in the cited block on the cited page. It does not prove that the extracted value belongs in that field, so check green fields against the page and check every amber claim.

### Where does my data live?

Under `/home/ubuntu/workspace` on the instance: models, documents, page images and the search index. It survives Stop and is removed by Delete.

### Can I run this on my own hardware?

The models and vLLM are published openly; see [vLLM](https://github.com/vllm-project/vllm), the model cards linked above, and the `compose.yaml` in this folder. Use the models within the terms of their licences.

### How do I update to a newer version?

The images and models are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `compose.yaml` on your own copy and test the result before relying on it.

## Acceptable use and safety

Upload only documents you are allowed to process. Answers come from a language model: check every amber claim, and check green claims against the page before you rely on them. Do not use the output as legal, tax or financial advice.

## Guides and related Launchables

- Step-by-step guide: [Parse documents with NVIDIA Nemotron Parse and Nemotron Omni](https://www.9owls.com/guides/parse-documents-with-nemotron-parse-and-omni/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- A full retrieval app: [Self-host RAGFlow with local models](https://www.9owls.com/guides/self-host-ragflow-with-local-models/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/nemotron-parse-document-agent/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Omni Studio](https://www.9owls.com/launchables/nemotron-omni-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9cKCTehBUEgzwkv7tqk9gZK)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS)); [RAGFlow on Nemotron](https://www.9owls.com/launchables/ragflow-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8amkBXTPnhVDHsznOXkc6jOf9))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA Nemotron 3 Nano Omni is licensed by NVIDIA Corporation under the [NVIDIA Open Model Agreement](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-agreement/). By deploying with this model you accept its terms.
- NVIDIA Nemotron Parse and NVIDIA Nemotron Embed: see their model cards for licence terms.
- vLLM, pypdfium2 (PDFium) and Pillow under their own open-source licences.
- The sample documents are published by the U.S. Department of the Treasury, the IRS and the U.S. General Services Administration.
- `compose.yaml`, the inline app and this README: Apache-2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
