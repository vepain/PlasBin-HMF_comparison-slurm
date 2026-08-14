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
declare -r METHOD_CODE="pbhmf_rfpl"  # choose among the list of method codes
declare -r METHOD_TOOL="pbhmf"       # must be "pbhmf" or "pbf", and respecting method_code
declare -r PLASMIDNESS_THRESHOLD=0.5 # plasmidness threshold (0.5 = default)
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
# shellcheck source=../../envs/filter-bins.sh
source "$BENCH_ENVS_DIR/filter-bins.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")

FILT_METHOD_CODE="$METHOD_CODE"_filt

case "$METHOD_TOOL" in
"pbhmf")
    bins_tsv=$(get_pbhmf_pbf_bin_pred "$smp_uid" "$METHOD_CODE")
    filtered_bins_tsv=$(get_pbhmf_pbf_bin_pred "$smp_uid" "$FILT_METHOD_CODE")
    ;;
"pbf")
    bins_tsv=$(get_pbf_bin_pred "$smp_uid" "$METHOD_CODE")
    filtered_bins_tsv=$(get_pbf_bin_pred "$smp_uid" "$FILT_METHOD_CODE")
    ;;
*)
    echo "method_tool must be 'pbhmf' or 'pbf'"
    exit 1
    ;;
esac

plm_tsv=$(get_plm_pbhmf_rfpl_tsv "$smp_uid")
seeds_tsv=$(get_seeds_pbhmf_rfpl_tsv "$smp_uid")

py_script="$BENCH_SCRIPTS_DIR/filter_bins/filter_pbf_bins.py"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(get_uni_bin_dir "$smp_uid" "$FILT_METHOD_CODE")"

# ---------------------------------------------------------------------------- #
# Filtering
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid filter $METHOD_CODE bins"

mkdir -p "$(dirname "$filtered_bins_tsv")"

python3 "$py_script" rm-low-plm \
    "$bins_tsv" "$plm_tsv" "$seeds_tsv" "$filtered_bins_tsv" \
    --plm-thr "$PLASMIDNESS_THRESHOLD"
