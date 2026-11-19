# Nemotron Parse Document Agent

Turn PDFs and scans into cited answers and JSON on your own GPU. [NVIDIA Nemotron Parse](https://huggingface.co/nvidia/NVIDIA-Nemotron-Parse-2.0) reads each page of a document of up to 200 pages and maps its layout into text, tables and titles with bounding boxes. [NVIDIA Nemotron Embed](https://huggingface.co/nvidia/Nemotron-3.5-Embed-1B-BF16) indexes those blocks for search. [NVIDIA Nemotron 3 Nano Omni](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4) answers questions and fills JSON fields, citing the page and block behind every claim. All three models are served by [vLLM](https://github.com/vllm-project/vllm) on this GPU; no document leaves the instance.

Current versions: vLLM v0.33.0 (image pinned by digest), NVIDIA-Nemotron-Parse-2.0 at revision 4e021c03edc92e715d5d788921a927d0cbb4b4d1, Nemotron-3.5-Embed-1B-BF16 at revision e24ca1e346bcc53572bd7bdc02b3e8ebf66c197c, Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4 at revision 16993199e436da4ba75ddc410855f87e0d996ee6, Python 3.12.12, pypdfium2 5.15.2, Pillow 13.0.0

Last smoke: none yet

## What you get

One web app behind the `open-doc-agent` link:

- **Documents** - three sample buttons and an upload box for PDF, PNG or JPEG files up to 200 MB. A PDF with more than 200 pages is refused with a message asking you to split it.
- **Pages** - every page as a thumbnail with the layout blocks Nemotron Parse found drawn on it.
- **Ask** - a question in plain words returns an answer split into claims. Each claim carries a chip such as `p.3 Table`: green when the quote it cites was found in that block, amber with the reason when it was not. Click a chip to highlight the block on its page.
- **Extract** - pick a form preset and get JSON in which every field has a value, page, box and a verified flag. A field is marked verified only when its value is copied word for word from the cited block.

## Sample documents

The sample buttons load three public U.S. Government documents:

| Button | Source | Pages |
| --- | --- | --- |
| Financial Report of the U.S. Government, FY 2025 executive summary | [fiscal.treasury.gov](https://fiscal.treasury.gov/system/files/2026-03/executive-summary-2025.pdf) | 11 |
| IRS Form W-9 | [irs.gov](https://www.irs.gov/pub/irs-prior/fw9--2024.pdf) | 6 |
| GSA Standard Form 1449 | [gsa.gov](https://www.gsa.gov/system/files/SF1449-21.pdf) | 2 |

The documents are not stored in this repository. The app downloads each one from its source on first use and refuses it if its size or SHA-256 checksum does not match the value pinned in `compose.yaml`.

## Try these three tasks

1. Load the Financial Report executive summary and ask: "Make a table of the government's net cost, net operating cost and budget deficit for FY 2025, with a citation for each figure."
2. Load IRS Form W-9, open Extract and run the `IRS Form W-9 layout` preset.
3. Load GSA Standard Form 1449, open Extract and run the `Contract form review` preset.

## How it works

| Service | What it does | Where it listens |
| --- | --- | --- |
| `vllm-parse` | Nemotron Parse, one page image in, layout blocks out | localhost:8001 |
| `vllm-embed` | Nemotron Embed, vectors for search | localhost:8002 |
| `vllm-omni` | Nemotron 3 Nano Omni, answers and JSON with tool calls | localhost:8000 |
| `app` | Python web app: ingest, hybrid search (SQLite FTS5 plus vectors), agent loop and citation check | port 8080, the `open-doc-agent` Secure Link |

Ingest renders each PDF page to an image, sends it to Nemotron Parse, splits the blocks into chunks and indexes them. A question runs a short agent loop: Nemotron 3 Nano Omni may search again or look at a page image, then answers in a fixed JSON schema. For a question that asks for figures, the best-matching table blocks are always shown to the model. The citation check marks a claim verified only when the cited block was retrieved, the quote matches that block, every number in the claim appears in it and, when the page's PDF text layer holds that block, the quote is also in the text layer. If a quote was copied from a different block than the one cited, the claim is re-cited to the block that holds the quote and passes the same check there, and the answer records the original citation. If a claim's number is missing from the block it cites but a table block shown to the model prints it, the claim is re-cited to that table row, and the answer records the original quote. For a question that asks for figures, every claim must state its number. A year such as 2025 does not count as a figure. In Extract, a field that a preset ties to the form page must cite a block on that page. If a claim or field fails, the model gets one retry with the reasons and the list of blocks it may cite; an Extract retry also gets the blocks found by searching for each failed field. Two Extract fields that hold the same value both fail, because the check cannot tell which one is right. The app runs these checks against fixed test cases each time it starts (`python /data/app/app.py --selftest`) and does not start if any case fails.

The three vLLM servers start one after another and share the GPU: 12, 10 and 66 percent of its memory.

## Settings

| Parameter | Type | Default | Notes |
| --- | --- | --- | --- |
| `OMNI_MODEL` | Choice | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-NVFP4` | The model that answers and extracts. |
| `HF_TOKEN` | Text | none | Optional Hugging Face read token; raises download rate limits. Choose "Use a secret" to bind a saved secret (the option may be off for your account) or paste a read token. |

## Use the model APIs from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

Use ports 8001 and 8002 the same way for Nemotron Parse and Nemotron Embed.

## Data and persistence

Everything lives under `/home/ubuntu/workspace` on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- Documents, page images and the search index: `/home/ubuntu/workspace/doc-agent/docs` and `/home/ubuntu/workspace/doc-agent/index.db`
- App packages: `/home/ubuntu/workspace/doc-agent/pip`

They survive a stop and start. They are removed when the instance is deleted.

## Default compute

Default compute: 1x NVIDIA L40S 48 GB, 200 GiB disk. You can pick other compute on the deploy page; all three models must fit in GPU memory together.

## Stop and delete

- **Stop** the instance when you are not using it. Models, documents and the index are kept. Storage is still billed while stopped.
- **Delete** the instance when you are finished. This removes it and all of its data.

## Troubleshooting

- The first start downloads three models; the app page shows which services are up in its status bar.
- Setup log: `sudo cat /var/log/brev-workspace.log`
- If the services are not back a few minutes after a start: `cd /home/ubuntu/workspace && sudo docker compose up -d`

## Acceptable use and safety

Upload only documents you are allowed to process. Answers come from a language model: check every amber claim, and check green claims against the page before you rely on them. Do not use the output as legal, tax or financial advice.

## Credits and licences

- NVIDIA Nemotron 3 Nano Omni is licensed by NVIDIA Corporation under the [NVIDIA Open Model Agreement](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-agreement/). By deploying with this model you accept its terms.
- NVIDIA Nemotron Parse and NVIDIA Nemotron Embed: see their model cards for licence terms.
- vLLM, pypdfium2 (PDFium) and Pillow under their own open-source licences.
- The sample documents are published by the U.S. Department of the Treasury, the IRS and the U.S. General Services Administration.
- `compose.yaml`, the inline app and this README: Apache-2.0, see `LICENSE`.
