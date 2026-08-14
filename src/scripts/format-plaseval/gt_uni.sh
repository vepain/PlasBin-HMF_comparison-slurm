#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r len_thr=100 # minimum contig length (matches FILTERED_100 assemblies)

# ---------------------------------------------------------------------------- #
# Format the ground truth into a PlasEval TSV (usually a one-off; the *.gt.tsv
# files may already exist).
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/format-plaseval/configure.sh
source "$BENCH_ENVS_DIR/format-plaseval/configure.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")

gt_csv=$(get_gt_csv "$smp_uid")

gt_tsv=$(get_gt_plaseval_fmt "$smp_uid")
outdir=$(dirname "$gt_tsv")
outfile=$(basename "$gt_tsv")

py_script="$BENCH_SCRIPTS_DIR/format-plaseval/format_ground_truth.py"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$outdir"

# ---------------------------------------------------------------------------- #
# Formatting
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid format ground truth"

python3 "$py_script" \
    --gt "$gt_csv" \
    --len_thr "$len_thr" \
    --outdir "$outdir" \
    --outfile "$outfile"
