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
declare -r METHOD_CODE="pbhmf_rfpl"
declare -r METHOD_FORMAT="pbhmf" # In pbf, pbhmf, mob or gpcc
# ---------------------------------------------------------------------------- #
# Format PB-HMF binning results into a PlasEval prediction TSV.
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

gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")

case "$METHOD_FORMAT" in
"pbf")
    results=$(get_pbf_bin_pred "$smp_uid" "$METHOD_CODE")
    tool="pbf"
    ;;
"pbhmf")
    results=$(get_pbhmf_pbf_bin_pred "$smp_uid" "$METHOD_CODE")
    tool="pbf"
    ;;
"gpcc")
    results=$(get_gpcc_bin_pred "$smp_uid" "$METHOD_CODE")
    tool="gp"
    ;;
"mob")
    results=$(get_mob_bin_pred "$smp_uid" "$METHOD_CODE")
    tool="mob"
    ;;
esac

pred_tsv=$(get_pred_plaseval_fmt "$smp_uid" "$METHOD_CODE")
outdir=$(dirname "$pred_tsv")
outfile=$(basename "$pred_tsv")

py_script="$BENCH_SCRIPTS_DIR/format-plaseval/format_binning_results.py"

gfa="$SLURM_TMPDIR/$smp_uid.gfa"
gunzip -c "$gfa_gz" >"$gfa"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$outdir"

# ---------------------------------------------------------------------------- #
# Formatting
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid format pred $METHOD_CODE"

python3 "$py_script" \
    --tool "$tool" \
    --assembly "$gfa" \
    --results "$results" \
    --outdir "$outdir" \
    --outfile "$outfile"
