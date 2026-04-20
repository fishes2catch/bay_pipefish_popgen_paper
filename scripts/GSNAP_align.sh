#!/bin/bash

# GSNAP alignment of RAD-seq reads to Syngnathus leptorhynchus reference genome
# Currey et al. — Ichthyology and Herpetology
#
# Aligns demultiplexed RAD-seq reads for all 142 individuals to the S. leptorhynchus
# reference genome (GCA_054491065.1, index: Slep_gsnap_genome).
# Produces sorted BAM files for input to Stacks ref_map.pl.
#
# Prerequisites:
#   - GSNAP index built with GSNAP_build.sh
#   - Demultiplexed reads in ${READS_DIR} (from process_radtags, Stacks)
#   - samtools available
#
# See Section 0.1 of bay_pipefish_popgen_analysis.qmd for full pipeline context.

#SBATCH --partition=compute
#SBATCH --account=nereus
#SBATCH --job-name=GSNAP_align
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --time=1-00:00:00
#SBATCH --nodes=1
#SBATCH --mem=5GB
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24

ml gmap-gsnap/2024-05-07
ml samtools/1.19

# Paths
READS_DIR="/home/mcurrey/G/Slep_analysis/process_radtags/reads/"
GENOME_DB="/home/mcurrey/G/Slep_analysis/Lepto_genome"
GENOME_NAME="Slep_gsnap_genome"
ALIGN_DIR="/home/mcurrey/G/Slep_analysis/GSNAP/"

mkdir -p ${ALIGN_DIR}

# All 116 individuals 
samples="
3900.0001 3900.0002 3900.0003 3900.0004 3900.0005 3900.0006 3900.0007
3900.0008 3900.0009 3900.0010 3900.0011 3900.0012 3900.0013 3900.0014
3900.0015 3900.0016 3900.0017 3900.0018 3900.0019 3900.0020 3900.0021
3900.0022 3900.0023 3900.0024 3900.0025 3900.0026 3900.0027 3900.0028
3900.0029 3900.0030 3900.0031 3900.0032 3900.0033 3900.0034 3900.0035
3900.0036 3900.0037 3900.0038 3900.0039 3900.0040 3900.0041 3900.0042
3900.0043 3900.0044 3900.0045 3900.0046 3900.0047 3900.0048 3900.0049
3900.0050
3899.0001 3899.0002 3899.0003 3899.0004 3899.0005 3899.0006 3899.0007
3899.0008 3899.0009 3899.0010 3899.0011 3899.0012 3899.0013 3899.0014
3899.0015 3899.0016 3899.0017 3899.0018 3899.0019 3899.0020 3899.0021
3899.0022 3899.0023 3899.0024 3899.0025 3899.0026 3899.0027 3899.0028
3899.0029 3899.0030 3899.0031 3899.0032 3899.0033 3899.0034 3899.0035
3899.0036 3899.0037 3899.0038 3899.0039 3899.0040 3899.0041 3899.0042
3899.0043 3899.0044 3899.0045 3899.0046 3899.0047 3899.0048 3899.0049
3899.0050 3899.0051 3899.0052 3899.0053 3899.0054 3899.0055 3899.0056
3899.0057 3899.0058 3899.0059 3899.0060 3899.0061 3899.0062 3899.0063
3899.0064 3899.0065 3899.0066"

echo "Starting GSNAP alignment: $(date)"

for sample in ${samples}; do
    echo "Aligning ${sample}: $(date)"

    # Align with GSNAP — unpaired_uniq output used for downstream Stacks analysis
    gsnap \
        --gunzip \
        -t 24 \
        -n 1 \
        --quiet-if-excessive \
        --split-output=${ALIGN_DIR}${sample} \
        -A sam \
        -m 2 \
        -i 2 \
        -d ${GENOME_NAME} \
        -D ${GENOME_DB} \
        ${READS_DIR}${sample}.fq.gz

    # Convert uniquely mapped reads (unpaired_uniq) to sorted BAM
    samtools view -bS ${ALIGN_DIR}${sample}.unpaired_uniq \
        | samtools sort -o ${ALIGN_DIR}${sample}.bam

    # Remove intermediate SAM files to save space
    rm -f ${ALIGN_DIR}${sample}.unpaired_uniq \
          ${ALIGN_DIR}${sample}.unpaired_mult \
          ${ALIGN_DIR}${sample}.paired_uniq \
          ${ALIGN_DIR}${sample}.paired_mult \
          ${ALIGN_DIR}${sample}.unpaired_transloc \
          ${ALIGN_DIR}${sample}.halfmapping_uniq \
          ${ALIGN_DIR}${sample}.halfmapping_transloc \
          ${ALIGN_DIR}${sample}.nomapping \
          ${ALIGN_DIR}${sample}.concordant_uniq \
          ${ALIGN_DIR}${sample}.concordant_mult

    echo "  Completed ${sample}"
done

echo "GSNAP alignment complete: $(date)"
echo "Sorted BAM files written to: ${ALIGN_DIR}"
