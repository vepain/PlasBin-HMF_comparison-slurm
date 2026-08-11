#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/filter_bins_uni/%A/%a.out
#SBATCH --error=logs/filter_bins_uni/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r method_code="pbhmf_rfpl" # choose among the list of method codes
declare -r plm_thr=0.5              # plasmidness threshold (0.5 = default)
# ---------------------------------------------------------------------------- #
# Filter PlasBin-flow/HMF bins (remove low-plasmidness contigs) to mimic
# gplasCC outputs.
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/pbhmf.sh
source "$BENCH_ENVS_DIR/pbhmf.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_spe_smp_id "$SAMPLES_CSV")

bin_dir=$(get_uni_bin_dir "$smp_uid" "$method_code")
bins_tsv="$bin_dir/bins.tsv"
filtered_bins_tsv="$bin_dir/bins_filt.tsv"

plm_tsv=$(get_plm_pbhmf_rfpl_tsv "$smp_uid")
seeds_tsv=$(get_seeds_pbhmf_rfpl_tsv "$smp_uid")

py_script="$BENCH_SCRIPTS_DIR/filter_bins/filter_pbf_bins.py"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$bin_dir")"

# ---------------------------------------------------------------------------- #
# Filtering
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid filter $method_code bins"

python3 "$py_script" rm-low-plm \
    "$bins_tsv" "$plm_tsv" "$seeds_tsv" "$filtered_bins_tsv" \
    --plm-thr "$plm_thr"
