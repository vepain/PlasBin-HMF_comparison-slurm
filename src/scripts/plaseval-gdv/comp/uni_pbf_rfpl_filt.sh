#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-1242
#SBATCH --account=def-chauvec
#SBATCH --output=logs/plaseval-gdv/comp/uni_pbf_rfpl_filt/%A/%a.out
#SBATCH --error=logs/plaseval-gdv/comp/uni_pbf_rfpl_filt/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
source "$BENCH_ROOT_DIR/scripts/config.sh"

# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r alpha=0.5
# ---------------------------------------------------------------------------- #

method_code="pbf_rfpl_filt"

# ---------------------------------------------------------------------------- #
# Set directory paths
# ---------------------------------------------------------------------------- #
# tools_dir="$BENCH_ROOT_DIR/TOOLS/PlasEval/src"
tools_dir="$BENCH_ROOT_DIR/run_scripts/plaseval/PlasEval/src"

bin_res_dir="$BENCH_ROOT_DIR/DATA/RESULTS/FORMATTED_BINS/UNICYCLER/BINNING_RESULTS"
gt_dir="$BENCH_ROOT_DIR/DATA/RESULTS/FORMATTED_BINS/UNICYCLER/GROUND_TRUTH"

alpha_dir="ALPHA_${alpha//./}"
output_dir="$BENCH_ROOT_DIR/DATA/RESULTS/EVALUATIONS/UNICYCLER/COMP/$alpha_dir"

samples_csv="$BENCH_ROOT_DIR/completed_samples.csv"
# ---------------------------------------------------------------------------- #

smp_uid=$(get_spe_smp_id "$samples_csv")

echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid"

source "$BENCH_ROOT_DIR/ENVS/env_plaseval/bin/activate"
module load scipy-stack

#
# Running PlasEval for the method
#
echo "$SLURM_ARRAY_TASK_ID $smp_uid $method_code"

cd "$tools_dir" || exit 1

python plaseval.py \
    comp \
    --l "$bin_res_dir/$smp_uid.$method_code.tsv" \
    --r "$gt_dir/$smp_uid.gt.tsv" \
    --p $alpha \
    --out_file "$output_dir/${smp_uid}_${method_code}_gt.out" \
    --log_file "$output_dir/${smp_uid}_${method_code}_gt.log"

deactivate
