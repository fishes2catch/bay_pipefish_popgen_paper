#!/usr/bin/env Rscript

# Generate Slep_LGs_MB.txt — chromosome coordinate offset table
# Currey et al. — Ichthyology and Herpetology
#
# Creates the linkage group coordinate file used in Section 1 of
# bay_pipefish_popgen_analysis.qmd to convert chromosome-specific bp
# positions to whole-genome Mb coordinates for FST Manhattan plots.
#
# Input: scaffold lengths from the S. leptorhynchus reference genome
#        (GCA_054491065.1), derived from gmap_build output (GSNAP_build.sh).
#        Only the first 22 scaffolds (putative chromosomes) are retained.
#
# Output: Slep_LGs_MB.txt — tab-delimited file with columns:
#   chr       : chromosome number (1-22)
#   groups    : linkage group name (groupI - groupXXII)
#   LGs.len   : chromosome length in bp
#   LGs.breaks: cumulative genomic offset in bp (used as coordinate origin)
#
# Place output in the input/ directory before rendering the QMD.

# Scaffold lengths from gmap_build output (Slep.hic.p_ctg.FINAL.fa)
# Source: GSNAP_build.sh output log, HiC_scaffold_1 through HiC_scaffold_22
scaffold_lengths <- c(
  26086575,  # HiC_scaffold_1
  26032178,  # HiC_scaffold_2
  21285762,  # HiC_scaffold_3
  19312871,  # HiC_scaffold_4
  18377461,  # HiC_scaffold_5
  17477932,  # HiC_scaffold_6
  16984605,  # HiC_scaffold_7
  14633033,  # HiC_scaffold_8
  14454529,  # HiC_scaffold_9
  13358272,  # HiC_scaffold_10
  12795673,  # HiC_scaffold_11
  11569821,  # HiC_scaffold_12
  11493817,  # HiC_scaffold_13
  11130394,  # HiC_scaffold_14
  10390547,  # HiC_scaffold_15
   9992591,  # HiC_scaffold_16
   9145537,  # HiC_scaffold_17
   8171095,  # HiC_scaffold_18
   7753189,  # HiC_scaffold_19
   7533203,  # HiC_scaffold_20
   7496533,  # HiC_scaffold_21
   7361318   # HiC_scaffold_22
)

roman <- c("I","II","III","IV","V","VI","VII","VIII","IX","X",
           "XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX",
           "XXI","XXII")

LGs.info <- data.frame(
  chr       = 1:22,
  groups    = paste0("group", roman),
  LGs.len   = scaffold_lengths,
  LGs.breaks = c(0, cumsum(scaffold_lengths[-length(scaffold_lengths)]))
)

write.table(LGs.info,
            file      = "Slep_LGs_MB.txt",
            sep       = "\t",
            quote     = FALSE,
            row.names = FALSE,
            col.names = TRUE)

cat("Slep_LGs_MB.txt written successfully.\n")
cat("Chromosomes:", nrow(LGs.info), "\n")
cat("Total genome span:",
    round(sum(LGs.info$LGs.len) / 1e6, 1), "Mb\n")
