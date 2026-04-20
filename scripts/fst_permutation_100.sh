#!/bin/bash 

#SBATCH --partition=compute
#SBATCH --account=nereus
#SBATCH --job-name=fst_permutation_100
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --time=0-12:00:00
#SBATCH --nodes=1
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=4

ml stacks/2.68

# FULL TEST - 100 permutations
NPERMS=100
WORKING_DIR=$(pwd)
STACKS_DIR="$WORKING_DIR"
ORIGINAL_POPMAP="$WORKING_DIR/250630_separate_filtered_popmap.txt"
OUTPUT_DIR="$WORKING_DIR/fst_permutation_100"

# Use the observed Fst
OBSERVED_FST="0.0074"
echo "Starting permutation test with $NPERMS permutations"
echo "Observed Fst: $OBSERVED_FST"

# Create output directory
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

# Initialize results file
> permuted_fst_values.txt

# Run permutations
for i in $(seq 1 $NPERMS); do
    echo "Running permutation $i of $NPERMS ($(date))"
    
    mkdir -p ./perm_$i
    cd ./perm_$i
    
    # Create properly shuffled popmap
    cut -f1 $ORIGINAL_POPMAP > sample_names.txt
    cut -f2 $ORIGINAL_POPMAP | shuf > shuffled_populations.txt
    paste sample_names.txt shuffled_populations.txt > permuted_popmap_$i.txt
    
    # Run populations
    populations -P $STACKS_DIR -M ./permuted_popmap_$i.txt --hwe -r 0.8 -R 0.8 --min-maf 0.05 --max-obs-het 0.7 --fstats -t 4 > populations_output.log 2>&1
    
    # Extract Fst
    if grep -q "mean Fst:" populations_output.log; then
        PERM_FST=$(grep "mean Fst:" populations_output.log | awk '{print $4}' | sed 's/;//')
        if [[ $PERM_FST =~ ^[0-9]*\.?[0-9]+$ ]]; then
            echo $PERM_FST >> ../permuted_fst_values.txt
            echo "  -> Fst: $PERM_FST"
        else
            echo "NA" >> ../permuted_fst_values.txt
            echo "  -> Failed extraction"
        fi
    else
        echo "NA" >> ../permuted_fst_values.txt
        echo "  -> No Fst found"
    fi
    
    # Clean up
    rm -f sample_names.txt shuffled_populations.txt populations_output.log permuted_popmap_$i.txt
    rm -f "$STACKS_DIR"/populations.* 2>/dev/null
    
    cd $OUTPUT_DIR
done

# Calculate final statistics
echo "=========================================="
echo "PERMUTATION TEST COMPLETED"
echo "=========================================="

SIGNIFICANT_PERMS=$(awk -v obs="$OBSERVED_FST" '$1 != "NA" && $1 >= obs {count++} END {print count+0}' permuted_fst_values.txt)
TOTAL_VALID=$(awk '$1 != "NA" {count++} END {print count+0}' permuted_fst_values.txt)
P_VALUE=$(awk -v sig="$SIGNIFICANT_PERMS" -v total="$TOTAL_VALID" 'BEGIN {if(total>0) printf "%.6f", sig/total; else print "NA"}')

echo "Observed Fst: $OBSERVED_FST"
echo "Number of permutations: $NPERMS"
echo "Valid permutations: $TOTAL_VALID"
echo "Permuted Fst >= observed: $SIGNIFICANT_PERMS"
echo "P-value: $P_VALUE"

# Save results
cat > permutation_test_final_results.txt << EOF
FINAL PERMUTATION TEST RESULTS
==============================
Observed Fst: $OBSERVED_FST
Number of permutations: $NPERMS
Valid permutations: $TOTAL_VALID
Permuted Fst >= observed: $SIGNIFICANT_PERMS
P-value: $P_VALUE
Test date: $(date)
Parameters: --hwe -r 0.8 -R 0.8 --min-maf 0.05 --max-obs-het 0.7 --fstats

Statistical Interpretation:
$(if (( $(echo "$P_VALUE < 0.05" | bc -l) )); then echo "SIGNIFICANT: Populations are genetically differentiated"; else echo "NOT SIGNIFICANT: No evidence of population structure"; fi)
EOF

echo "Results saved to permutation_test_final_results.txt"
echo "Completed at $(date)"
