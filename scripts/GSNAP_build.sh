#!/bin/bash

# Build GSNAP genome index for bay pipefish (Syngnathus leptorhynchus)
# Currey et al. — Ichthyology and Herpetology
#
# Builds the GSNAP alignment index from the S. leptorhynchus reference genome.
# The genome file (Slep.hic.p_ctg.FINAL.fa) corresponds to NCBI GenBank
# assembly accession GCA_054491065.1. Download from:
# https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_054491065.1/
#
# Output database name: Slep_gsnap_genome
# This name must match the -d flag in all subsequent GSNAP alignment commands.
#
# See Section 0.1 of bay_pipefish_popgen_analysis.qmd for alignment details.

#SBATCH --account=nereus
#SBATCH --partition=compute
#SBATCH --job-name=GSNAP_build
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --time=0-04:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=28

ml gmap-gsnap/2024-05-07

genomefa="Slep.hic.p_ctg.FINAL.fa"
dbpath="./"
dbname="Slep_gsnap_genome"

gmap_build -D ${dbpath} -d ${dbname} ${genomefa}
