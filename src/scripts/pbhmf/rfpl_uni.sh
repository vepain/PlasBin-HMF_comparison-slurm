#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/pbhmf_rfpl_uni/%A/%a.out
#SBATCH --error=logs/pbhmf_rfpl_uni/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r method_code="pbhmf_rfpl"
# ---------------------------------------------------------------------------- #
# Run PlasBin-HMF binning (RFPlasmid plasmidness + seeds).
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
smp_uid=$(get_spe_smp_id "$SAMPLES_CSV")

gfa_gz=$(get_assembly_gfa_gz "$smp_uid")
plm_tsv=$(get_plm_pbhmf_rfpl_tsv "$smp_uid")
seeds_tsv=$(get_seeds_pbhmf_rfpl_tsv "$smp_uid")

output_dir=$(get_bin_dir "$BENCH_DATA_DIR" "$smp_uid" "$method_code")

# pangebin reads a plain GFA; unzip to the node-local scratch.
gfa="$SLURM_TMPDIR/$smp_uid.gfa"
gunzip -c "$gfa_gz" >"$gfa"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running PlasBin-HMF
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $method_code"

mkdir -p "$output_dir"

# TODO: CHECK USAGE from pangebin
pangebin asm-pbf hmf "$gfa" "$seeds_tsv" "$plm_tsv" \
    --outdir "$output_dir" \
    --bin-cfg "$BIN_CONFIG_YAML" \
    --gurobi-cfg "$GUROBI_CONFIG_YAML"
