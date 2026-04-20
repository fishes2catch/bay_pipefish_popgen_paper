# docs/

This directory contains supplementary documentation for reproducing the analysis in Currey et al.

## Contents

| File | Description |
|------|-------------|
| `session_info.txt` | R session info from final Quarto render (packages and versions) |
| `talapas_job_scripts.md` | SLURM job script details for Talapas HPC runs (Stacks, GSNAP, permutations, bootstraps) |
| `structure_parameters.md` | Full STRUCTURE v2.3.4 run parameters and CLUMPAK settings |
| `neestimator_settings.md` | NeEstimator v2 settings and output (Pcrit values, Ne results) |
| `genodive_settings.md` | Genodive v3.04 PCA settings |

## Notes

Session info is generated automatically at the end of `bay_pipefish_popgen_analysis.qmd`
via `sessionInfo()`. Copy the rendered output here after the final analysis run.

GUI software (STRUCTURE, CLUMPAK, NeEstimator, Genodive) cannot be run
programmatically. Parameter details for each are documented in Section 0 of the
Quarto document and summarized in the corresponding files above.
