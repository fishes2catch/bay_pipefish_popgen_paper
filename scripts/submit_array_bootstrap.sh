#!/bin/bash

# Quick submission script for array bootstrap analysis
# This script submits the array job and sets up monitoring

echo "========================================="
echo "BOOTSTRAP FST ARRAY ANALYSIS SUBMISSION"
echo "========================================="
echo "This will submit 50 parallel jobs for bootstrap Fst analysis"
echo "Total iterations: 1000 (50 jobs × 20 iterations each)"
echo "Expected runtime: 1-2 hours"
echo ""

# Check if required files exist
if [[ ! -f "fst_bootstrap_array.sh" ]]; then
    echo "ERROR: fst_bootstrap_array.sh not found!"
    echo "Make sure the array job script is in the current directory."
    exit 1
fi

if [[ ! -f "combine_array_results.sh" ]]; then
    echo "ERROR: combine_array_results.sh not found!"
    echo "Make sure the combine script is in the current directory."
    exit 1
fi

if [[ ! -f "plink_working/wl_chr1-22" ]]; then
    echo "ERROR: Whitelist file not found: plink_working/wl_chr1-22"
    echo "Make sure your whitelist file exists."
    exit 1
fi

if [[ ! -f "240418_Lepto_popmap_reduced_reduced.txt" ]]; then
    echo "ERROR: Popmap file not found: 240418_Lepto_popmap_reduced_reduced.txt"
    echo "Make sure your popmap file exists."
    exit 1
fi

echo "All required files found ✓"
echo ""

# Make scripts executable
chmod +x fst_bootstrap_array.sh
chmod +x combine_array_results.sh

echo "Submitting array job..."
JOB_ID=$(sbatch fst_bootstrap_array.sh | grep -o '[0-9]\+')

if [[ -n "$JOB_ID" ]]; then
    echo "✓ Array job submitted successfully!"
    echo "Job ID: $JOB_ID"
    echo ""
    echo "Monitor progress with:"
    echo "  squeue -u $(whoami)"
    echo "  squeue -j $JOB_ID"
    echo ""
    echo "Check individual array job outputs:"
    echo "  ls fst_bootstrap_array-${JOB_ID}_*.out"
    echo ""
    echo "When all jobs complete, run:"
    echo "  bash combine_array_results.sh"
    echo ""
    echo "========================================="
    echo "Job submission complete!"
    echo "Check back in 1-2 hours for results."
    echo "========================================="
else
    echo "ERROR: Failed to submit job!"
    exit 1
fi

