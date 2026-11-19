# Three tasks to try

Run one long task at a time; if a tool reports it is paused, wait about a minute and retry.

## 1. Repair the GROMACS suite

Prompt:

> List the GROMACS cases, then repair all five. For each case: reset it, read the inputs, find the problem, fix it with write_file or gmx_solvate_genion, run gmx_grompp, then run gmx_mdrun for 5000 steps. Finish with a table of what you changed and "Repaired N of 5".

The five cases (lysozyme 1AKI, 10 ps runs):

| Case | Problem |
| --- | --- |
| C1 | An unsupported cut-off scheme in md.mdp |
| C2 | The solvated system is not neutralised |
| C3 | The topology and the coordinates disagree on the water count |
| C4 | The time step is too large for the constraints |
| C5 | The thermostat coupling groups are missing |

A case counts as repaired when `gmx grompp` accepts it with no warnings and the 10 ps GPU run finishes. To check a case yourself, open a terminal on the instance:

```
cd /home/ubuntu/workspace && sudo docker compose exec science-tools python3 /opt/science/cases/C1/check.py /work/SESSION/C1
```

`SESSION` is the folder name under `/home/ubuntu/workspace/science-agent/work`.

## 2. Rank molecules with RDKit

Prompt:

> Compute RDKit descriptors for these SMILES and rank them by QED, explaining each rank in one line: CC(=O)Oc1ccccc1C(=O)O, CN1C=NC2=C1C(=O)N(C(=O)N2C)C, CC(C)Cc1ccc(cc1)C(C)C(=O)O, c1ccccc1, CCO

Then:

> Run the LitmusBench check.

The check asks the local model 50 LitmusBench v0.2 questions chosen with a fixed seed and reports how many it answered correctly. It takes up to 45 minutes. Results are saved under `evals` with item ids and scores only.

## 3. Read a reaction scheme

Upload an image of a reaction scheme (PNG or JPEG) and ask:

> Read this reaction scheme. Return JSON with "reactants" and "products" as SMILES, validate every SMILES with smiles_validate, and fix any that are invalid.
