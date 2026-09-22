#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --array=2-837
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r METHOD_CODE="pbf_rfpl"
# ---------------------------------------------------------------------------- #
# Run PlasBin-flow binning (RFPlasmid plasmidness + seeds).
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/plasbin-flow.sh
source "$BENCH_ENVS_DIR/plasbin-flow.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$ONLY_LABELLED_SAMPLES_TSV")
#
# Inputs
#
gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
plm_tsv=$(get_plm_pbf_rfpl_tsv "$smp_uid")
seeds_tsv=$(get_seeds_pbf_platon_tsv "$smp_uid")

# GC-content probabilities are a PlasBin-flow-only input: computed on the fly.
# gc_probabilities reads a "sample,gfa" CSV and writes <out_dir>/<sample>.gc.tsv
gc_dir="$SLURM_TMPDIR/gc"
gc_input_csv="$SLURM_TMPDIR/gc_input.csv"
printf 'sample,gfa\n%s,%s\n' "$smp_uid" "$gfa_gz" >"$gc_input_csv"
gc_tsv="$gc_dir/$smp_uid.gc.tsv"
#
# Outputs
#
bins_tsv=$(get_pbf_bin_pred "$smp_uid" "$METHOD_CODE")
output_dir=$(dirname "$bins_tsv")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running PlasBin-flow
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $METHOD_CODE"

# PlasBin-flow opens -log_file before it creates -out_dir: the directory must exist
mkdir -p "$output_dir"

python "$PBF_CODE_DIR/plasbin_utils.py" gc_probabilities \
    --input_file "$gc_input_csv" \
    --out_dir "$gc_dir" \
    --tmp_dir "$SLURM_TMPDIR/gc_tmp" \
    --log_file "$SLURM_TMPDIR/gc_probabilities.log"

python "$PBF_CODE_DIR/plasbin_flow.py" \
    -ag "$gfa_gz" \
    -gc "$gc_tsv" \
    -score "$plm_tsv" \
    -seeds "$seeds_tsv" \
    -out_dir "$output_dir" \
    -out_file "$(basename "$bins_tsv")" \
    -log_file "$output_dir/plasbin_flow.log"
