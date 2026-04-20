#!/bin/bash

# Filter population map to remove low-quality individuals
# Currey et al. — Ichthyology and Herpetology
#
# Removes individuals that failed VCFtools quality filtering from the
# population map used in downstream Stacks populations runs.
#
# Filtering criteria (applied in VCFtools):
#   - Missing data rate > 12%
#   - Excess heterozygosity or high inbreeding (F < -0.10 or F > 0.25)
#   - Combined moderate missing data (>10%) and heterozygosity deviation
#     (F < -0.05 or F > 0.20)
#
# Two-step filtering:
#   Step 1 (this script): 26 individuals removed by VCFtools criteria
#   Step 2 (Stacks):      10 additional individuals removed internally
#                         by Stacks populations via -r 0.8 and -R 0.8
#                         coverage thresholds
#   Total removed:        36 individuals (14 Causeway, 22 Valino Island)
#   Final retained:       80 individuals (36 Causeway + 44 Valino Island)
#
# Input:  250630_together_popmap.txt        (106 individuals passing alignment)
# Output: 250630_separate_filtered_popmap.txt  (90 individuals, used in Stacks run)
#
# See Section 0.1 of bay_pipefish_popgen_analysis.qmd and Methods (RAD library
# construction and genotyping) for full filtering details.

# Samples removed based on VCFtools quality filtering (Step 1 — 26 individuals)
cat > samples_to_remove.txt << EOF
3899.0008
3899.0019
3899.0025
3899.0027
3899.0037
3899.0038
3899.0043
3899.0045
3899.0051
3899.0053
3899.0054
3899.0055
3899.0059
3900.0004
3900.0005
3900.0007
3900.0009
3900.0010
3900.0011
3900.0016
3900.0019
3900.0021
3900.0025
3900.0032
3900.0041
3900.0046
EOF

# Remove flagged samples from popmap
grep -v -f samples_to_remove.txt 250630_together_popmap.txt \
    > 250630_separate_filtered_popmap.txt

# Report counts
BEFORE=$(wc -l < 250630_together_popmap.txt)
AFTER=$(wc -l < 250630_separate_filtered_popmap.txt)
REMOVED=$((BEFORE - AFTER))

echo "Individuals before filtering: ${BEFORE}"
echo "Individuals after filtering:  ${AFTER}"
echo "Individuals removed:          ${REMOVED}"
echo ""
echo "Note: Stacks populations (-r 0.8 -R 0.8) will remove an additional"
echo "10 individuals based on locus coverage thresholds, yielding the"
echo "final 80 individuals (36 Causeway + 44 Valino Island) used in analysis."

# Clean up
rm -f samples_to_remove.txt