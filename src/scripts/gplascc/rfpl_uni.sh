#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r METHOD_CODE="gpcc_rfpl"
declare -r LENGTH_FILTER=1 # gplasCC contig length filter (gplas default: 1000)
# ---------------------------------------------------------------------------- #
# Run gplasCC binning with RFPlasmid as the classifier (custom mode).
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/gplascc.sh
source "$BENCH_ENVS_DIR/gplascc.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")
#
# Inputs
#
gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
plm_tsv=$(get_plm_gplas_rfpl_tsv "$smp_uid")

# gplasCC only reads unzipped GFA
gfa="$SLURM_TMPDIR/$smp_uid.gfa"
gunzip -c "$gfa_gz" >"$gfa"
#
# Outputs
#
output_dir=$(get_uni_bin_dir "$smp_uid" "$METHOD_CODE")
bins_tab=$(get_gpcc_bin_pred "$smp_uid" "$METHOD_CODE")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running gplasCC
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $METHOD_CODE"

mkdir -p "$output_dir"

apptainer run -C -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    gplas \
    -i "$gfa" \
    -P "$plm_tsv" \
    -o "$output_dir" \
    -n "$smp_uid" \
    -l "$LENGTH_FILTER"

# gplasCC writes the per-contig bin assignment in "$output_dir/results/<name>_results.tab"
mv "$output_dir/results/${smp_uid}_results.tab" "$bins_tab"
