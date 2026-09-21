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
# Format RFPlasmid classification into PlasBin-flow plasmidness input TSV file
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

rfpl_pred_csv=$(get_rfplasmid_prediction_csv "$smp_uid")
pbf_plm_tsv=$(get_plm_pbf_rfpl_tsv "$smp_uid") # RFPlasmid -> PBf plasmidness

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$pbf_plm_tsv")"

# ---------------------------------------------------------------------------- #
# Formatting
# ---------------------------------------------------------------------------- #
echo_sample_job "$smp_uid" \
    "format RFPlasmid classification into PlasBin-flow plasmidness TSV file"

mkdir -p "$(dirname "$pbf_plm_tsv")"

# RFPlasmid classification -> PBf plasmidness TSV
apptainer run "$APPTAINER_IMG" rfplasmid-to-pbf-plm "$rfpl_pred_csv" "$pbf_plm_tsv"
