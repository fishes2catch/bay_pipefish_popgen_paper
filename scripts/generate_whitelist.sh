#!/bin/bash

# Generate chromosome whitelist and rename scaffolds in PLINK map
# Currey et al. — Ichthyology and Herpetology
#
# Two-step pipeline run after the initial Stacks populations run
# (see Stacks_250210.sh):
#
#   Step 1: Extract locus catalog IDs mapping to HiC_scaffold_1 through
#           HiC_scaffold_22 from the PLINK map file to create a whitelist
#           (wl_chr1-22). This whitelist restricts all downstream populations
#           runs to the 22 putative chromosomes.
#           See Methods: "A whitelist of loci including reads from only
#           the first 22 scaffolds, which are likely the chromosomes in
#           this species, was then used in a second populations run."
#
#   Step 2: Rename HiC_scaffold_N chromosome labels to numeric IDs (1-22)
#           in the PLINK map file for compatibility with PLINK LD tools.
#
# Input:  Populations_initial/populations.plink.map
#         (from initial Stacks populations run — see Stacks_250210.sh)
# Output: plink_working/wl_chr1-22
#         (whitelist of locus IDs for chromosomes 1-22)
#
# See Section 0.1 of bay_pipefish_popgen_analysis.qmd for full context.

WORKING_DIR=$(pwd)
PLINK_MAP="${WORKING_DIR}/Populations_initial/populations.plink.map"

mkdir -p plink_working

# ============================================================
# Step 1: Extract locus IDs for scaffolds 1-22 (whitelist)
# ============================================================

echo "Step 1: Generating whitelist for HiC_scaffold_1-22 ($(date))"

> plink_working/wl_chr1-22  # Initialize empty whitelist

for i in $(seq 1 22); do
    grep "^HiC_scaffold_${i}\b" ${PLINK_MAP} \
        | cut -f2 \
        | sed -r 's/^([0-9]+)_([0-9]+)/\1/' \
        | sort -n \
        | uniq >> plink_working/wl_chr1-22
done

NLOCI=$(wc -l < plink_working/wl_chr1-22)
echo "Whitelist complete: ${NLOCI} loci on chromosomes 1-22"
echo "Whitelist written to: plink_working/wl_chr1-22"

# ============================================================
# Step 2: Rename HiC_scaffold_N to integers in PLINK map
# ============================================================

echo "Step 2: Renaming HiC_scaffold_N to integers in PLINK map ($(date))"

# Backup original map file
cp ${PLINK_MAP} ${PLINK_MAP}.bak

for i in $(seq 1 22); do
    sed -i -r "s/^(HiC_scaffold_${i})(\b.+)$/${i}\2/" ${PLINK_MAP}
done

echo "Scaffold renaming complete"
echo "Original map backed up to: ${PLINK_MAP}.bak"
echo ""
echo "Next step: run Stacks_250210.sh with --whitelist plink_working/wl_chr1-22"
echo "Completed: $(date)"
