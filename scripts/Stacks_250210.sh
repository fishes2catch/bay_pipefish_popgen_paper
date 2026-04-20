#!/bin/bash

# Stacks populations run for bay pipefish (Syngnathus leptorhynchus) population genomics
# Currey et al. — Ichthyology and Herpetology
#
# This script runs the Stacks populations module on the final filtered SNP set.
# Input: gstacks catalog in working directory, filtered population map, SNP whitelist
# Output: Populations_together_250630/ containing VCF, PLINK, STRUCTURE, and FST files
#
# See Section 0.1 of bay_pipefish_popgen_analysis.qmd for full pipeline context.

#SBATCH --partition=compute
#SBATCH --account=nereus
#SBATCH --job-name=populations_separate
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --time=0-01:00:00
#SBATCH --nodes=1
#SBATCH --mem=5GB
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1

ml stacks/2.68

populations \
    -P ./ \
    -M 250630_together_filtered_popmap.txt \
    -O ./Populations_together_250630 \
    --whitelist ./plink_working/wl_chr1-22 \
    -t 8 \
    -r 0.8 \
    -R 0.8 \
    --min-maf 0.05 \
    --fstats \
    --smooth \
    --write-single-snp \
    --plink \
    --structure \
    --vcf
