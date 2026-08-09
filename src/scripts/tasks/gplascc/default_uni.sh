#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-1242
#SBATCH --output=logs/default_uni/%A/%a.out
#SBATCH --error=logs/default_uni/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

# Run gplasCC in default mode on FIR Alliance cluster

umask 007

declare -r home_dir="/project/def-chauvec/wg-anoph/benchmarking"
declare -r results_dir="$home_dir/DATA/RESULTS"
declare -r uni_dir="$home_dir/DATA/ASSEMBLY_FILES/FILTERED_100/UNICYCLER"
declare -r samples_csv="$home_dir/completed_samples.csv"

declare -r output_dir="$results_dir/BINNING/GPLASCC/DEFAULT/UNICYCLER"
mkdir -p "$output_dir" 2>/dev/null

declare -r db_dir="$home_dir/ENVS/PlasmidCC_Databases"

export THREADS=16

# Load apptainer module
module load apptainer

declare -r app_tainer_img="$home_dir/ENVS/apptainer_gplascc.sif"

# Get species and sample ID
#
function get_spe_smp_id {
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${samples_csv} | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${samples_csv} | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
}

# Get the species from the species-sample ID
#
# Usage:
#   > spe_smp_id="abau-SAMN41094848"
#   > species=$(get_species "$spe_smp_id")
#   > echo $species
#   Acinetobacter_baumannii
#
# By default, return "Escherichia_coli"
#
function get_species {
    local spe_smp_id=$1

    spe_code=$(echo "$spe_smp_id" | cut -d "-" -f 1)

    if [[ "$spe_code" == "abau" ]]; then
        database_path="Acinetobacter_baumannii"
    elif [[ "$spe_code" == "ecol" ]]; then
        database_path="Escherichia_coli"
    elif [[ "$spe_code" == "efae" ]]; then
        database_path="Enterococcus_faecium"
    elif [[ "$spe_code" == "saur" ]]; then
        database_path="Staphylococcus_aureus"
    elif [[ "$spe_code" == "kpne" ]]; then
        database_path="Klebsiella_pneumoniae"
    else
        database_path="Escherichia_coli"
    fi

    echo "$database_path"
}

# Get the plasmid centrifuge database file path from the species-sample ID
#
# Usage:
#   > spe_smp_id="abau-SAMN41094848"
#   > database_file=$(get_database_file "$spe_smp_id")
#   > echo $database_file
#
# By default, return the database for Escherichia coli
#
function get_database_file {
    local spe_smp_id=$1

    spe_code=$(echo "$spe_smp_id" | cut -d "-" -f 1)

    if [[ "$spe_code" == "abau" ]]; then
        database_path="$db_dir/A_baumannii_plasmid_db"
    elif [[ "$spe_code" == "ecol" ]]; then
        database_path="$db_dir/chromosome_plasmid_db"
    elif [[ "$spe_code" == "efae" ]]; then
        database_path="$db_dir/E_faecium_c_plasmid_db"
    elif [[ "$spe_code" == "saur" ]]; then
        database_path="$db_dir/S_aureus_plasmid_db"
    elif [[ "$spe_code" == "kpne" ]]; then
        database_path="$db_dir/K_pneumoniae_plasmid_db"
    else
        database_path="Escherichia_coli"
    fi

    echo "$database_path"
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

    echo "${spe_smp_id}-plcc-short"
}

# Run gplasCC
#
# Arguments:
# 1. Path to gfa graph (unzipped)
# 2. Name of the species, see function get_species
# 3. GplasCC experiment output directory
#
# Usage:
function run_gplascc {
    local asm_gfa=$1
    local spe_smp_id=$2
    local output_dir=$3

    local species
    species=$(get_species "$spe_smp_id")

    local database_path
    database_path=$(get_database_file "$spe_smp_id")

    local file_prefix
    file_prefix=$(result_file_prefix "$spe_smp_id")

    echo "Run gplasCC in the current directory, with apptainer"
    # Run gplasCC in the current directory, with apptainer
    #
    # The sample results will be in "$output_dir/results" directory
    apptainer run -C -B /project -B /scratch -W "$SLURM_TMPDIR" "$app_tainer_img" gplas -o "$output_dir" -i "$asm_gfa" -p "$database_path" -n "$file_prefix"
}

spe_smp_id=$(get_spe_smp_id)

output_dir="$output_dir/$spe_smp_id"
mkdir -p "$output_dir" 2>/dev/null

uni_data_smp_dir="$uni_dir/$spe_smp_id"
gfa_gz="$uni_data_smp_dir/assembly.gfa.gz"
gfa="$output_dir/assembly.gfa"
gunzip -k "$gfa_gz" -c >"$gfa"

echo "$SLURM_ARRAY_TASK_ID $spe_smp_id"

run_gplascc "$gfa" "$spe_smp_id" "$output_dir"

result_dir="$output_dir/results"
mv "$result_dir/$(result_file_prefix "$spe_smp_id")"* "$output_dir"
rm -rf "$output_dir"

rm "$gfa"
