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
# shellcheck source=../../envs/plasbin-hmf/configure.sh
source "$BENCH_ENVS_DIR/plasbin-hmf/configure.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_spe_smp_id "$SAMPLES_CSV")
#
# Inputs (bridge)
#
old_data_dir="/project/def-chauvec/wg-anoph/benchmarking/DATA"
gfa_gz="$old_data_dir/ASSEMBLY_FILES/FILTERED_100/UNICYCLER/$smp_uid/assembly.gfa.gz"
plm_tsv="$old_data_dir/FORMATTED_INPUT/RFPLASMID/FILTERED_100/UNICYCLER/INPUT_PBF/${smp_uid}_scores.tsv"
seeds_tsv="$old_data_dir/FORMATTED_INPUT/PLATON/FILTERED_100/UNICYCLER/INPUT_PBF/${smp_uid}_seeds.tsv"
#
# Outputs
#
output_dir=$(get_bin_dir "$BENCH_DATA_DIR" "$smp_uid" "$method_code")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running PlasBin-HMF
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $method_code"

mkdir -p "$output_dir"

plasbin-hmf run "$gfa_gz" "$plm_tsv" "$seeds_tsv" \
    -o "$output_dir" \
    --config "$PBHMF_CONFIG_YAML" \
    --gurobi-config"$GUROBI_CONFIG_YAML"
