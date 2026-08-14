#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r method_code="pbhmf_rfpl" # choose among the list of method codes

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/plaseval-gdv.sh
source "$BENCH_ENVS_DIR/plaseval-gdv.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")

#
# Bridge
#
old_data_dir="/project/def-chauvec/wg-anoph/benchmarking/DATA"
gt_dir="$old_data_dir/RESULTS/FORMATTED_BINS/UNICYCLER/GROUND_TRUTH"

pred_tsv=$(get_pred_plaseval_fmt "$smp_uid" "$method_code")
gt_tsv="$gt_dir/$smp_uid.gt.tsv"

min_len=$(get_min_len "$smp_uid")
if [[ -z "$min_len" ]]; then ## if min_len is empty, exclude the --min_len argument
    min_len_arg=""
else
    min_len_arg="--min_len $min_len"
fi

#
# New conventionnal data
#
output_dir=$(get_plaseval_eval_meth_dir "$method_code")
plaseval_out=$(get_plaseval_eval_out "$output_dir" "$smp_uid")
plaseval_log=$(get_plaseval_eval_log "$output_dir" "$smp_uid")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$output_dir"

# ---------------------------------------------------------------------------- #
# Running PlasEval (GDV fork) for the method
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $method_code"

mkdir -p "$output_dir"

apptainer run -C -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    eval \
    --pred "$pred_tsv" \
    --gt "$gt_tsv" \
    --out_file "$plaseval_out" \
    --log_file "$plaseval_log" \
    $min_len_arg
