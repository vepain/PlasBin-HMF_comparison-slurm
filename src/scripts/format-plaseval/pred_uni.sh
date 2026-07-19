#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/format_plaseval_pred_uni/%A/%a.out
#SBATCH --error=logs/format_plaseval_pred_uni/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r method_code="pbhmf_rfpl" # append _filt to format the filtered bins
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
# shellcheck source=../../envs/py-tools.sh
source "$BENCH_ENVS_DIR/py-tools.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_spe_smp_id "$SAMPLES_CSV")

gfa_gz=$(get_assembly_gfa_gz "$smp_uid")

# Filtered bins live alongside the raw bins in the same (unfiltered) method dir.
bin_dir=$(get_bin_dir "$BENCH_DATA_DIR" "$smp_uid" "${method_code%_filt}")
if [[ "$method_code" == *_filt ]]; then
    results="$bin_dir/bins_filt.tsv"
else
    results="$bin_dir/bins.tsv"
fi

pred_tsv=$(get_pred_plaseval_fmt "$smp_uid" "$method_code")
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
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid format pred $method_code"

python3 "$py_script" \
    --tool pbf \
    --assembly "$gfa" \
    --results "$results" \
    --outdir "$outdir" \
    --outfile "$outfile"
