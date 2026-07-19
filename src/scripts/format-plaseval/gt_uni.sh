#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/format_plaseval_gt_uni/%A/%a.out
#SBATCH --error=logs/format_plaseval_gt_uni/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r len_thr=100 # minimum contig length (matches FILTERED_100 assemblies)
# ground truth CSV directory (external); TODO: point at the real location.
declare -r gt_dir="TODO:GROUND_TRUTH_CSV_DIR"
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
# shellcheck source=../../envs/py-tools.sh
source "$BENCH_ENVS_DIR/py-tools.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_spe_smp_id "$SAMPLES_CSV")

gt_csv="$gt_dir/$smp_uid/short.gfa.csv"

gt_tsv=$(get_gt_plaseval_fmt "$smp_uid")
outdir=$(dirname "$gt_tsv")
outfile=$(basename "$gt_tsv")

# NOTE: format_ground_truth.py is not yet in this repo (see plan Open items);
# drop it in this same folder once recovered.
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
