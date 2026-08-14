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
# Format RFPlasmid outputs (plasmidness + seeds) into PB-HMF/PBf input TSV
# files, using the pangebin format.py helper.
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/pbhmf.sh
source "$BENCH_ENVS_DIR/pbhmf.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")

rfplasmid_dir=$(get_rfplasmid_out_dir "$smp_uid")

plm_tsv=$(get_plm_pbhmf_rfpl_tsv "$smp_uid")     # RFPlasmid -> PBf plasmidness
seeds_tsv=$(get_seeds_pbhmf_rfpl_tsv "$smp_uid") # RFPlasmid -> PBf seeds

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$plm_tsv")"

# ---------------------------------------------------------------------------- #
# Formatting
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid format PB-HMF input"

mkdir -p "$(dirname "$plm_tsv")" "$(dirname "$seeds_tsv")"

# TODO: confirm the format.py subcommand names against the installed pangebin.
# RFPlasmid classification -> PBf plasmidness TSV
python3 "$FORMAT_PY" rfplasmid-to-pbf "$rfplasmid_dir" "$plm_tsv"

# RFPlasmid classification -> PBf seed contigs TSV
python3 "$FORMAT_PY" rfplasmid-to-pbf-seeds "$rfplasmid_dir" "$seeds_tsv"
