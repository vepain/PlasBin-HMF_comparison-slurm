#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-1242
#SBATCH --output=logs/uni_all/%A/%a.out
#SBATCH --error=logs/uni_all/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

# Change the following addresses to the address of the tools directory in your project

umask 007

# Get species and sample UID
#
# Arguments:
# 1. Samples file
#
# Usage:
#   > spe_smp_id=$(get_spe_smp_id "$samples_file")
function get_spe_smp_id {
    local smp_file=$1
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
}

# Home directory
home_dir="/project/def-chauvec/wg-anoph/benchmarking"
gt_dir="/project/ctb-chauvec/tvinar/genomes/fatih"
asm_dir="$home_dir/DATA/ASSEMBLY_FILES/FILTERED_100"

out_dir="$home_dir/DATA/RESULTS/FORMATTED_BINS"

envs_dir="$home_dir/ENVS"
scripts_dir="$home_dir/scripts/format_input_plaseval"

samples_csv="$home_dir/completed_samples.csv"
#samples_csv="test_samples.csv"

smp_uid=$(get_spe_smp_id "$samples_csv")

echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid"

source "$envs_dir/env_py311/bin/activate"
module load scipy-stack

echo "${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID} $smp_uid gunzipping UNICYCLER"

asm_smp_dir="$asm_dir/UNICYCLER/$smp_uid"
gfa_gz_smp="$asm_smp_dir/assembly.gfa.gz"
gunzip -k "$gfa_gz_smp" 2>/dev/null

#
# Ground truth
#
python "$scripts_dir/format_ground_truth.py" --gt $gt_dir/$smp_uid/short.gfa.csv --len_thr 100 \
    --outdir $out_dir/UNICYCLER/GROUND_TRUTH --outfile ${smp_uid}.gt.tsv

rm "$gfa_smp"

deactivate
