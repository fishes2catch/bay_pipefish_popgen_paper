#!/bin/bash

#SBATCH --partition=compute
#SBATCH --account=nereus
#SBATCH --job-name=fst_bootstrap_array
#SBATCH --output=%x-%A_%a.out
#SBATCH --error=%x-%A_%a.err
#SBATCH --time=0-02:00:00           # 2 hours per array job
#SBATCH --nodes=1
#SBATCH --mem=16GB                  # Less RAM per node since we're parallelizing
#SBATCH --cpus-per-task=8           # Fewer CPUs per node
#SBATCH --array=1-50                # 50 array jobs, each doing 20 iterations = 1000 total

ml stacks/2.68

# ARRAY JOB BOOTSTRAP FST ANALYSIS
# Each array job runs a subset of bootstrap iterations in parallel
# 50 jobs × 20 iterations each = 1000 total iterations

ITERATIONS_PER_JOB=20              # Number of iterations per array job
N_LOCI=1000                        # Number of loci to sample in each bootstrap
WORKING_DIR=$(pwd)
STACKS_DIR="$WORKING_DIR"
POPMAP_FILE="$WORKING_DIR/250630_separate_filtered_popmap.txt"
ORIGINAL_WHITELIST="$WORKING_DIR/plink_working/wl_chr1-22"
OUTPUT_DIR="$WORKING_DIR/fst_bootstrap_array"

# Population names for Fst calculation
POP1="1"                           # First population 
POP2="2"                           # Second population

# Additional populations parameters
POPULATIONS_PARAMS="-r 0.8 -R 0.8 --min-maf 0.05 --max-obs-het 0.7 --write-single-snp --hwe --fstats -t 8"

# Calculate iteration range for this array job
START_ITER=$(( (SLURM_ARRAY_TASK_ID - 1) * ITERATIONS_PER_JOB + 1 ))
END_ITER=$(( SLURM_ARRAY_TASK_ID * ITERATIONS_PER_JOB ))

# Create output directories
mkdir -p "${OUTPUT_DIR}/whitelists"
mkdir -p "${OUTPUT_DIR}/results"
mkdir -p "${OUTPUT_DIR}/populations_runs"
mkdir -p "${OUTPUT_DIR}/array_results"

# Print job information
echo "========================================="
echo "SLURM Job ID: $SLURM_JOB_ID"
echo "Array Job ID: $SLURM_ARRAY_JOB_ID"
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Node: $HOSTNAME"
echo "Started: $(date)"
echo "Working directory: $(pwd)"
echo "Iterations: $START_ITER to $END_ITER"
echo "Using 8 CPUs and 16GB RAM per node"
echo "========================================"

# Check if required files exist
if [[ ! -f "$ORIGINAL_WHITELIST" ]]; then
    echo "ERROR: Original whitelist not found: $ORIGINAL_WHITELIST"
    exit 1
fi

if [[ ! -f "$POPMAP_FILE" ]]; then
    echo "ERROR: Popmap file not found: $POPMAP_FILE"
    exit 1
fi

# Count total SNPs available for sampling
TOTAL_SNPS=$(wc -l < "$ORIGINAL_WHITELIST")
echo "Found ${TOTAL_SNPS} SNPs available for bootstrap sampling"

if [[ $TOTAL_SNPS -lt $N_LOCI ]]; then
    echo "WARNING: Requested ${N_LOCI} loci but only ${TOTAL_SNPS} available."
    echo "Adjusting sample size to ${TOTAL_SNPS}"
    N_LOCI=$TOTAL_SNPS
fi

# Function to extract Fst value from populations output - FIXED VERSION
extract_fst() {
    local run_dir=$1
    local fst_file="${run_dir}/populations.fst_summary.tsv"
    
    if [[ -f "$fst_file" ]]; then
        # Extract Fst value - format is: Pop1 Fst_value
        # Skip header line (NR > 1) and get the Fst value from column 2
        local fst_value=$(awk 'NR > 1 && NF >= 2 { print $2; exit }' "$fst_file")
        echo "$fst_value"
    else
        echo "ERROR: Fst file not found: $fst_file" >&2
        echo "NA"
    fi
}

# Array to store Fst values for this job
FST_VALUES=()

# Main bootstrap loop for this array job
START_TIME=$(date +%s)
echo "Starting bootstrap iterations $START_ITER to $END_ITER..."

for i in $(seq $START_ITER $END_ITER); do
    echo "Array ${SLURM_ARRAY_TASK_ID}: Bootstrap iteration $i"
    
    # Create unique whitelist for this iteration
    current_whitelist="${OUTPUT_DIR}/whitelists/whitelist_${i}.txt"
    current_output="${OUTPUT_DIR}/populations_runs/run_${i}"
    
    # Randomly sample N_LOCI from the original whitelist
    shuf -n $N_LOCI "$ORIGINAL_WHITELIST" > "$current_whitelist"
    
    # Create output directory for this run
    mkdir -p "$current_output"
    
    # Run populations with the subsampled whitelist
    populations -P "$STACKS_DIR" \
                -M "$POPMAP_FILE" \
                -O "$current_output" \
                --whitelist "$current_whitelist" \
                $POPULATIONS_PARAMS \
                > "${current_output}/populations.log" 2>&1
    
    # Check if populations ran successfully
    if [[ $? -eq 0 ]]; then
        # Extract Fst value
        fst_value=$(extract_fst "$current_output")
        
        if [[ "$fst_value" != "NA" && "$fst_value" != "" ]]; then
            FST_VALUES+=("$fst_value")
            echo "  Iteration $i: Fst = $fst_value"
        else
            echo "  WARNING: Could not extract Fst value for iteration $i"
            echo "  Check file: ${current_output}/populations.fst_summary.tsv"
        fi
    else
        echo "  ERROR: populations failed for iteration $i"
        echo "  Check log: ${current_output}/populations.log"
    fi
    
    # Optional: Clean up intermediate files to save space (uncomment if needed)
    # rm -rf "${current_output}/populations.haps.tsv"
    # rm -rf "${current_output}/populations.hapstats.tsv"
    # rm -rf "${current_output}/populations.sumstats.tsv"
done

# Save results from this array job
array_results_file="${OUTPUT_DIR}/array_results/fst_values_array_${SLURM_ARRAY_TASK_ID}.txt"
printf '%s\n' "${FST_VALUES[@]}" > "$array_results_file"

# Create a summary file for this array job
array_summary_file="${OUTPUT_DIR}/array_results/summary_array_${SLURM_ARRAY_TASK_ID}.txt"
echo "Array_Task_ID: $SLURM_ARRAY_TASK_ID" > "$array_summary_file"
echo "Start_Iteration: $START_ITER" >> "$array_summary_file"
echo "End_Iteration: $END_ITER" >> "$array_summary_file"
echo "Successful_Iterations: ${#FST_VALUES[@]}" >> "$array_summary_file"
echo "Total_Iterations: $ITERATIONS_PER_JOB" >> "$array_summary_file"
echo "Success_Rate: $(echo "scale=2; ${#FST_VALUES[@]} / $ITERATIONS_PER_JOB * 100" | bc -l)%" >> "$array_summary_file"
echo "Node: $HOSTNAME" >> "$array_summary_file"
echo "Start_Time: $(date -d @$START_TIME)" >> "$array_summary_file"
echo "End_Time: $(date)" >> "$array_summary_file"

# Final array job summary
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_TIME / 60))

echo ""
echo "========================================="
echo "ARRAY JOB ${SLURM_ARRAY_TASK_ID} COMPLETED!"
echo "Iterations: $START_ITER to $END_ITER"
echo "Runtime: ${MINUTES} minutes"
echo "Success rate: ${#FST_VALUES[@]}/$ITERATIONS_PER_JOB iterations"
echo "Results saved to: $array_results_file"
echo "Summary saved to: $array_summary_file"
echo "Completed: $(date)"
echo "========================================"

# Check if this is the last array job to complete
# If so, automatically start the combination process
EXPECTED_ARRAY_FILES=50
CURRENT_ARRAY_FILES=$(ls "${OUTPUT_DIR}/array_results/fst_values_array_"*.txt 2>/dev/null | wc -l)

if [[ $CURRENT_ARRAY_FILES -eq $EXPECTED_ARRAY_FILES ]]; then
    echo ""
    echo "🎉 ALL ARRAY JOBS APPEAR TO BE COMPLETE!"
    echo ""
    echo "Next step: Combine results"
    echo "Run: bash combine_array_results.sh"
    echo ""
fi
