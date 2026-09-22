#!/usr/bin/env bash
# DOCU must first do pbf_plm_rfpl
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
# Format (PlasBin-flow formatted) RFPlasmid classification into gplasCC classification input file
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
#
# Inputs
#
pbf_plm_tsv=$(get_plm_pbf_rfpl_tsv "$smp_uid") # PBf plasmidness from RFPlasmid
gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
#
# Output
#
gpcc_plm_tsv=$(get_plm_gplascc_rfpl_tsv "$smp_uid")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$gpcc_plm_tsv")"

# ---------------------------------------------------------------------------- #
# Formatting
# ---------------------------------------------------------------------------- #
echo_sample_job "$smp_uid" \
    "Format (PlasBin-flow formatted) RFPlasmid classification into gplasCC classification input file"

mkdir -p "$(dirname "$gpcc_plm_tsv")"

# RFPlasmid classification -> PBf plasmidness TSV
apptainer run "$APPTAINER_IMG" pbf-plm-to-gplascc-input "$pbf_plm_tsv" "$gfa_gz" "$gpcc_plm_tsv"
