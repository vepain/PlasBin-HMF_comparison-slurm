#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --array=2-837
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# Format Platon classification to PlasBin-flow seeds
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=src/envs/format-binning-inputs.sh
source "$BENCH_ENVS_DIR/format-binning-inputs.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$ONLY_LABELLED_SAMPLES_TSV")

platon_pred_tsv=$(get_platon_prediction_tsv "$smp_uid")
pbf_seeds_tsv=$(get_seeds_pbf_platon_tsv "$smp_uid") # Platon -> PBf seeds

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$pbf_seeds_tsv")"

# ---------------------------------------------------------------------------- #
# Formatting
# ---------------------------------------------------------------------------- #
echo_sample_job "$smp_uid" \
    "format PlasBin-flow seeds from Platon"

mkdir -p "$(dirname "$pbf_seeds_tsv")"

# Platon classification -> PBf seed contigs TSV
apptainer run "$APPTAINER_IMG" platon-to-pbf-seeds "$platon_pred_tsv" "$pbf_seeds_tsv"
