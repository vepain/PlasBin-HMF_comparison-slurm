#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-1242
#SBATCH --output=logs/rfpl_uni/%A/%a.out
#SBATCH --error=logs/rfpl_uni/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

# Run gplasCC with RFPlasmid as classifier input on FIR Alliance cluster
#
# Minimum requirement are marked as TODO comments

umask 007

declare -r home_dir="/project/def-chauvec/wg-anoph/benchmarking"
declare -r results_dir="$home_dir/DATA/RESULTS"
declare -r uni_dir="$home_dir/DATA/ASSEMBLY_FILES/FILTERED_100/UNICYCLER"
declare -r input_dir="$results_dir/FORMATTED_INPUT/RFPLASMID/UNICYCLER/INPUT_GPLAS"
declare -r samples_csv="$home_dir/completed_samples.csv"

declare -r all_smp_out_dir="$results_dir/BINNING/GPLASCC/CUSTOM_RFPLASMID/UNICYCLER"
mkdir -p "$all_smp_out_dir" 2>/dev/null

export THREADS=16

# Load apptainer module
module load apptainer

declare -r apptainer_img="$home_dir/ENVS/apptainer_gplascc.sif"

# Get species and sample ID
#
function get_sample_uid_from_slurm_array {
    local smp_file=$1
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
}

# Get the prefix of the result file
#
# Argument:
# 1. Species-sample ID
#
# Usage:
#   > spe_smp_id="abau-SAMN41094848"
#   > prefix=$(result_file_prefix "$spe_smp_id")
function result_file_prefix {
    local spe_smp_id=$1

    echo "${spe_smp_id}-rfpl-short"
}

# Run gplasCC
#
# Arguments:
# 1. Path to gfa graph (unzipped)
# 2. Path to gplasCC (formatted) plasmid classification input
# 3. Output directory of all the samples
# 4. Species-sample ID
function run_gplascc {
    local asm_gfa=$1
    local gplascc_input=$2
    local uid_out_dir=$3
    local spe_smp_id=$4

    mkdir -p "$uid_out_dir" 2>/dev/null

    local file_prefix
    file_prefix=$(result_file_prefix "$spe_smp_id")

    # Run gplasCC in the current directory, with apptainer
    #
    # The sample results will be in "$output_dir/results" directory
    apptainer run -C -B /project -B /scratch -W "$SLURM_TMPDIR" "$apptainer_img" gplas -o "$uid_out_dir" -i "$asm_gfa" -P "$gplascc_input" -n "$file_prefix" -l 1
}

spe_smp_id=$(get_sample_uid_from_slurm_array "$samples_csv")

smp_outdir="$all_smp_out_dir/$spe_smp_id"
mkdir -p "$smp_outdir" 2>/dev/null

gfa="$smp_outdir/assembly.gfa"

uni_data_smp_dir="$uni_dir/$spe_smp_id"
gfa_gz="$uni_data_smp_dir/assembly.gfa.gz"
gunzip -k "$gfa_gz" -c >"$gfa"

gplascc_input="$input_dir/${spe_smp_id}_scores.tsv"

echo "$SLURM_ARRAY_TASK_ID $spe_smp_id gplasCC+RFPlasmid"

run_gplascc "$gfa" "$gplascc_input" "$smp_outdir" "$spe_smp_id"

result_dir="$smp_outdir/results"
mv "$result_dir/$(result_file_prefix "$spe_smp_id")"* "$all_smp_out_dir"
rm -rf "$result_dir"

rm "$gfa"
