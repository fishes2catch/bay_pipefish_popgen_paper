# Analysis Pipeline Overview

## Bay Pipefish Population Genomics — Coos Bay, Oregon
### Currey et al. — *Ichthyology and Herpetology*

---

This document describes the complete analysis pipeline from raw sequencing
reads to final figures and tables. The pipeline has two phases:

- **Phase 1 — HPC (Talapas):** Steps 0–7 are run on the University of Oregon
  Talapas HPC cluster using SLURM job submission. Scripts are in `scripts/`.
- **Phase 2 — Local (R/Quarto):** Steps 8–18 are run locally by rendering
  `bay_pipefish_popgen_analysis.qmd`. All input files generated in Phase 1
  must be placed in `input/` before rendering.

See `bay_pipefish_popgen_analysis.qmd` Section 0 for full parameter details
for each step.

---

## Phase 1 — HPC Pipeline (Talapas)

### Step 0: Build GSNAP genome index

**Script:** `scripts/GSNAP_build.sh`

**Input:**
- `Slep.hic.p_ctg.FINAL.fa` — *S. leptorhynchus* reference genome
  (NCBI GenBank: GCA_054491065.1)

**Run:**
```bash
sbatch scripts/GSNAP_build.sh
```

**Output:**
- `Slep_gsnap_genome/` — GSNAP index directory

**Notes:** Only needs to be run once. Download genome from:
https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_054491065.1/

---

### Step 1: Align RAD-seq reads

**Script:** `scripts/GSNAP_align.sh`

**Input:**
- `Slep_gsnap_genome/` — GSNAP index (from Step 0)
- `process_radtags/reads/*.fq.gz` — demultiplexed reads for all individuals

**Run:**
```bash
sbatch scripts/GSNAP_align.sh
```

**Output:**
- `GSNAP/*.bam` — sorted BAM files for all 116 individuals

**Notes:** Only uniquely mapping reads are retained (`-n 1`). Up to 2
nucleotide mismatches and gap lengths of 2 allowed (`-m 2 -i 2`).

---

### Step 2: Filter population map

**Script:** `scripts/filter_popmap.sh`

**Input:**
- `250630_together_popmap.txt` — unfiltered population map (106 individuals)

**Run:**
```bash
bash scripts/filter_popmap.sh
```

**Output:**
- `250630_separate_filtered_popmap.txt` — filtered population map (90 individuals)

**Notes:** Removes 26 individuals that failed VCFtools quality criteria
(missing data, heterozygosity, inbreeding thresholds). An additional 10
individuals are removed by Stacks in Step 3 via `-r 0.8 -R 0.8`, yielding
the final 80 individuals (36 Causeway + 44 Valino Island).

---

### Step 3: Initial Stacks populations run

**Script:** `scripts/Stacks_250210.sh`

**Input:**
- Stacks catalog (from `ref_map.pl` — see QMD Section 0.1)
- `250630_separate_filtered_popmap.txt` — filtered population map (Step 2)

**Run:**
```bash
sbatch scripts/Stacks_250210.sh
```

**Output:**
- `Populations_initial/populations.plink.map` — used to generate whitelist
- `Populations_initial/populations.plink.ped`

**Notes:** This initial run is without a whitelist, used only to generate
the PLINK map file for whitelist creation in Step 4.

---

### Step 4: Generate chromosome whitelist

**Script:** `scripts/generate_whitelist.sh`

**Input:**
- `Populations_initial/populations.plink.map` — from Step 3

**Run:**
```bash
bash scripts/generate_whitelist.sh
```

**Output:**
- `plink_working/wl_chr1-22` — locus IDs for HiC_scaffold_1 through
  HiC_scaffold_22 (putative chromosomes)

**Notes:** Restricts all downstream analyses to the 22 putative chromosomes,
excluding unplaced scaffolds. Also renames scaffold labels to integers in
the PLINK map file for downstream PLINK compatibility.

---

### Step 5: Two-population Stacks run (separate)

**Script:** `scripts/Stacks_250210.sh` (re-run with whitelist and separate popmap)

**Input:**
- Stacks catalog
- `250630_separate_filtered_popmap.txt` — two populations (Causeway, Valino Island)
- `plink_working/wl_chr1-22` — chromosome whitelist (Step 4)

**Run:**
```bash
sbatch scripts/Stacks_250210.sh
```

**Output:**
- `Populations_separate_250630/populations.snps.vcf` — 6,074 SNPs
- `Populations_separate_250630/populations.fst_1-2.txt` — per-SNP FST
- `Populations_separate_250630/populations.structure` — STRUCTURE/PCA input
- `Populations_separate_250630/populations.plink.*` — PLINK files

**Used for:** FST analysis, PCA, STRUCTURE, kinship, permutation test,
bootstrap resampling (Sections 1–6 of QMD).

---

### Step 6: FST permutation test

**Script:** `scripts/fst_permutation_100.sh`

**Input:**
- Stacks catalog
- `250630_separate_filtered_popmap.txt`
- `plink_working/wl_chr1-22`

**Run:**
```bash
sbatch scripts/fst_permutation_100.sh
```

**Output:**
- `fst_permutation_100/permuted_fst_values.txt` — 100 permuted FST values

**Notes:** Run after Step 5 confirms the observed FST. Individuals randomly
reassigned to populations while preserving sample sizes. Runtime: ~12 hours.

---

### Step 7: FST bootstrap resampling

**Scripts:** `scripts/array_bootstrap_fst.sh`, `scripts/submit_array_bootstrap.sh`,
`scripts/combine_script_clear.sh`

**Input:**
- Stacks catalog
- `250630_separate_filtered_popmap.txt`
- `plink_working/wl_chr1-22`

**Run:**
```bash
bash scripts/submit_array_bootstrap.sh
```

Wait for all 50 array jobs to complete, then:

```bash
bash scripts/combine_script_clear.sh
```

**Output:**
- `fst_bootstrap_array/fst_bootstrap_values_combined.txt` — 1,000 bootstrap FST values

**Notes:** 50 SLURM array jobs × 20 iterations each = 1,000 total replicates.
Runtime: ~2 hours.

---

### Step 8: Combined single-population Stacks run (together)

**Script:** `scripts/Stacks_250210.sh` (re-run with combined popmap)

**Input:**
- Stacks catalog
- `250630_together_filtered_popmap.txt` — both locations combined (one population)
- `plink_working/wl_chr1-22` — chromosome whitelist (Step 4)

**Run:**
```bash
sbatch scripts/Stacks_250210.sh
```

**Output:**
- `Populations_together_250630/populations.snps.vcf` — 6,310 SNPs

**Used for:** LD analysis and Ne estimation (Sections 7–11 of QMD).

**Notes:** Run after Step 5 confirms panmixia between the two locations.
The `-r` flag is omitted because both locations are collapsed into one
population.

---

## Phase 1 — GUI Software (run manually)

### Step 9: PCA in Genodive

**Input:** `Populations_separate_250630/populations.structure`

Run PCA using covariance method in Genodive v3.04. See
`docs/genodive_settings.md` for full parameter details.

**Output:** `250630_genetic_pca.txt` → place in `input/`

---

### Step 10: STRUCTURE analysis

**Scripts:** `scripts/strauto_noninteractive.py`, `scripts/input.py`

**Input:** `Populations_separate_250630/populations.structure`

See `docs/structure_parameters.md` for full parameter details.
Note: requires Python 2 and was run on the University of Oregon
Genome computing cluster (now decommissioned).

**Output:** CLUMPAK-processed bar plot → Figure 3

---

### Step 11: NeEstimator

Run NeEstimator v2 on the GenePop file generated in QMD Section 11.
See `docs/neestimator_settings.md` for settings.

---

## Phase 2 — Local R/Quarto Pipeline

### Prepare input files

Before rendering, place the following files in `input/`:

| File | Generated by | QMD Section |
|------|-------------|-------------|
| `populations.snps.vcf` | Step 5 (two-pop run) | 5 |
| `populations.fst_1-2.txt` | Step 5 (two-pop run) | 1 |
| `populations.structure` | Step 5 (two-pop run) | 0.7, 0.8 |
| `populations_combined.snps.vcf` | Step 8 (combined run) | 0.3, 0.4 |
| `populations_pruned.bed/.bim/.fam` | QMD Section 0.3 (PLINK2) | 10, 11 |
| `Slep_full_LD.vcor` | QMD Section 0.4 (Beagle + PLINK2) | 7, 8, 9 |
| `Slep_LGs_MB.txt` | `scripts/generate_Slep_LGs_MB.R` | 1 |
| `permuted_fst_values.txt` | Step 6 | 3 |
| `fst_bootstrap_values_combined.txt` | Step 7 | 4 |
| `250630_genetic_pca.txt` | Step 9 (Genodive) | 2 |
| `Slep_pop.txt`, `pop1.txt`, `pop2.txt` | Created manually | 0.2 |

### Generate coordinate offset table

```bash
Rscript scripts/generate_Slep_LGs_MB.R
mv Slep_LGs_MB.txt input/
```

### Render the analysis

```bash
quarto render bay_pipefish_popgen_analysis.qmd
```

All figures and tables will be written to `output/`.

---

## Software Requirements

| Software | Version | Phase | Purpose |
|----------|---------|-------|---------|
| GSNAP | 2024-05-07 | HPC | Read alignment |
| Stacks | v2.68 | HPC | Genotyping, FST |
| samtools | v1.19 | HPC | BAM processing |
| PLINK2 | v2.0 | HPC/Local | LD pruning, Ne prep |
| Beagle | v5.4 | HPC | Haplotype phasing |
| Genodive | v3.04 | GUI | PCA |
| STRUCTURE | v2.3.4 | GUI | Clustering |
| CLUMPAK | — | GUI | STRUCTURE visualization |
| NeEstimator | v2 | GUI | LD-based Ne |
| R | ≥ 4.3 | Local | Analysis and figures |
| Quarto | ≥ 1.4 | Local | Reproducible pipeline |

---

## Directory Structure After Full Pipeline

```
bay_pipefish_popgen_paper/
├── bay_pipefish_popgen_analysis.qmd
├── input/                   # All Phase 1 outputs placed here
├── output/                  # All figures and tables written here
├── scripts/                 # HPC and utility scripts
└── docs/                    # Parameter documentation
```