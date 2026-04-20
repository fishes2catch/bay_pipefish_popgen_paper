#!/bin/bash

# Script to combine results from array bootstrap jobs
# Run this after all array jobs are complete

WORKING_DIR=$(pwd)
OUTPUT_DIR="$WORKING_DIR/fst_bootstrap_array"
COMBINED_RESULTS="${OUTPUT_DIR}/fst_bootstrap_values_combined.txt"

echo "Combining array job results..."
echo "Looking in: ${OUTPUT_DIR}/array_results/"

# Check if array results directory exists
if [[ ! -d "${OUTPUT_DIR}/array_results" ]]; then
    echo "ERROR: Array results directory not found: ${OUTPUT_DIR}/array_results"
    exit 1
fi

# Combine all array results
cat ${OUTPUT_DIR}/array_results/fst_values_array_*.txt > "$COMBINED_RESULTS"

# Count total values
TOTAL_VALUES=$(wc -l < "$COMBINED_RESULTS")
echo "Combined $TOTAL_VALUES Fst values from array jobs"

# Calculate statistics using R
echo "Calculating final statistics..."

R --slave << EOF
# Read combined Fst values
fst_values <- read.table("$COMBINED_RESULTS", header=FALSE)\$V1

# Remove any NA or infinite values
fst_values <- fst_values[is.finite(fst_values)]

# Calculate statistics
n_values <- length(fst_values)
mean_fst <- mean(fst_values)
median_fst <- median(fst_values)
sd_fst <- sd(fst_values)
se_fst <- sd_fst / sqrt(n_values)

# Calculate confidence intervals
ci_95 <- quantile(fst_values, c(0.025, 0.975))
ci_90 <- quantile(fst_values, c(0.05, 0.95))
ci_99 <- quantile(fst_values, c(0.005, 0.995))

# Save results
results <- data.frame(
    Statistic = c("N", "Mean", "Median", "SD", "SE", 
                  "CI_90_Lower", "CI_90_Upper", 
                  "CI_95_Lower", "CI_95_Upper",
                  "CI_99_Lower", "CI_99_Upper"),
    Value = c(n_values, mean_fst, median_fst, sd_fst, se_fst, 
              ci_90[1], ci_90[2], ci_95[1], ci_95[2], ci_99[1], ci_99[2])
)

# Write results to file
write.table(results, "${OUTPUT_DIR}/fst_statistics_final.txt", 
            row.names=FALSE, quote=FALSE, sep="\t")

# Print results to console
cat("\n=== FINAL BOOTSTRAP FST ANALYSIS RESULTS ===\n")
cat("Total successful iterations:", n_values, "\n")
cat("Mean Fst:", round(mean_fst, 6), "\n")
cat("Median Fst:", round(median_fst, 6), "\n")
cat("Standard deviation:", round(sd_fst, 6), "\n")
cat("Standard error:", round(se_fst, 6), "\n")
cat("90% Confidence Interval: [", round(ci_90[1], 6), ",", round(ci_90[2], 6), "]\n")
cat("95% Confidence Interval: [", round(ci_95[1], 6), ",", round(ci_95[2], 6), "]\n")
cat("99% Confidence Interval: [", round(ci_99[1], 6), ",", round(ci_99[2], 6), "]\n")

# Create publication-quality histogram
pdf("${OUTPUT_DIR}/fst_histogram_final.pdf", width=10, height=7)
par(mar=c(5,5,4,2))
hist(fst_values, breaks=50, 
     main="Bootstrap Distribution of Fst Values",
     xlab=expression(paste("F"[ST])),
     ylab="Frequency",
     col="lightblue", border="black",
     cex.main=1.4, cex.lab=1.2, cex.axis=1.1)

# Add statistics lines
abline(v=mean_fst, col="red", lwd=2, lty=1)
abline(v=ci_95, col="red", lwd=2, lty=2)
abline(v=median_fst, col="blue", lwd=2, lty=3)

# Add legend
legend("topright", 
       legend=c(paste("Mean =", round(mean_fst, 4)),
                paste("Median =", round(median_fst, 4)),
                "95% CI"), 
       col=c("red", "blue", "red"), 
       lty=c(1, 3, 2), lwd=2,
       cex=1.1)

# Add text box with sample size
text(x=par("usr")[2]*0.02, y=par("usr")[4]*0.9, 
     labels=paste("n =", n_values, "bootstrap replicates"), 
     adj=c(0,1), cex=1.1)

dev.off()

# Also create PNG version
png("${OUTPUT_DIR}/fst_histogram_final.png", width=10, height=7, units="in", res=300)
par(mar=c(5,5,4,2))
hist(fst_values, breaks=50, 
     main="Bootstrap Distribution of Fst Values",
     xlab=expression(paste("F"[ST])),
     ylab="Frequency",
     col="lightblue", border="black",
     cex.main=1.4, cex.lab=1.2, cex.axis=1.1)
abline(v=mean_fst, col="red", lwd=2, lty=1)
abline(v=ci_95, col="red", lwd=2, lty=2)
abline(v=median_fst, col="blue", lwd=2, lty=3)
legend("topright", 
       legend=c(paste("Mean =", round(mean_fst, 4)),
                paste("Median =", round(median_fst, 4)),
                "95% CI"), 
       col=c("red", "blue", "red"), 
       lty=c(1, 3, 2), lwd=2,
       cex=1.1)
text(x=par("usr")[2]*0.02, y=par("usr")[4]*0.9, 
     labels=paste("n =", n_values, "bootstrap replicates"), 
     adj=c(0,1), cex=1.1)
dev.off()

cat("Histograms saved to:\n")
cat("  - ${OUTPUT_DIR}/fst_histogram_final.pdf\n")
cat("  - ${OUTPUT_DIR}/fst_histogram_final.png\n")
EOF

echo ""
echo "========================================="
echo "ARRAY RESULTS COMBINATION COMPLETE!"
echo "Combined results saved to:"
echo "  - All Fst values: $COMBINED_RESULTS"
echo "  - Summary statistics: ${OUTPUT_DIR}/fst_statistics_final.txt"
echo "  - Histogram (PDF): ${OUTPUT_DIR}/fst_histogram_final.pdf"
echo "  - Histogram (PNG): ${OUTPUT_DIR}/fst_histogram_final.png"
echo "========================================="

