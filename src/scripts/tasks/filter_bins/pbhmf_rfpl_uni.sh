#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-1242
#SBATCH --output=logs/pbhmf_rfpl_uni/%A/%a.out
#SBATCH --error=logs/pbhmf_rfpl_uni/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

umask 007

# Get species and sample ID
#
function get_spe_smp_id {
    local samples_file=$1
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$samples_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$samples_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
}

home_dir="/project/def-chauvec/wg-anoph/benchmarking"

samples_file="$home_dir/completed_samples.csv"

bin_dir="$home_dir/DATA/RESULTS/BINNING/PB_HMF/RFPLASMID/FILTERED_100/UNICYCLER/"

fmt_in_dir="$home_dir/DATA/RESULTS/FORMATTED_INPUT"

module load python/3.11
source "$home_dir/ENVS/env_pbhmf_py311/bin/activate"

smp_uid=$(get_spe_smp_id "$samples_file")

plm_tsv="$fmt_in_dir/RFPLASMID/UNICYCLER/INPUT_PBF/${smp_uid}_scores.tsv"
seeds_tsv="$fmt_in_dir/PLATON/UNICYCLER/INPUT_PBF/${smp_uid}_seeds.tsv"

bins_tsv="$bin_dir/$smp_uid/bins.tsv"
filtered_bins_tsv="$bin_dir/$smp_uid/bins_filt.tsv"

echo "$SLURM_JOB_ID $SLURM_ARRAY_TASK_ID $smp_uid filtering PB-HMF+RFPlasmid bins"

py_script="$home_dir/scripts/filter_bins/filter_pbf_bins.py"
python3 "$py_script" rm-low-plm "$bins_tsv" "$plm_tsv" "$seeds_tsv" "$filtered_bins_tsv"
