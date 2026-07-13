#!/bin/bash
# ---------------------------------------------------------------------
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --account=def-chauvec
#SBATCH --array=2-1242
#SBATCH --output=logs/uni/%A/%a.out
#SBATCH --error=logs/uni/%A/%a.err
#SBATCH --mail-user=victorepain@disroot.org
#SBATCH --mail-type=ALL

# Run plasmidCC in default mode on FIR Alliance cluster
#
# Minimum requirement are marked as TODO comments

umask 007

# Load apptainer module
module load apptainer

declare -r home_dir="/project/def-chauvec/wg-anoph/benchmarking"

declare -r samples_file="$home_dir/completed_samples.csv"

declare -r app_tainer_img="$home_dir/ENVS/apptainer_plasmidcc.sif"

declare -r uni_data_dir="$home_dir/DATA/ASSEMBLY_FILES/FILTERED_100/UNICYCLER"
declare -r db_dir="$home_dir/ENVS/PlasmidCC_Databases"

declare -r results_dir="$home_dir/DATA/RESULTS"
declare -r plasmidcc_outdir="$results_dir/CLASSIFICATION/PLASMIDCC/FILTERED_100/UNICYCLER"
mkdir -p "$plasmidcc_outdir" 2>/dev/null

# Get species and sample ID
#
function get_spe_smp_id {
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$samples_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$samples_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
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
        database_path="$db_dir/chromosome_plasmid_db"
    fi

    echo "$database_path"
}

# Run plasmidCC
#
# Arguments:
# 1. Path to gfa graph (unzipped)
# 2. Output directory of all the samples
# 3. Species-sample ID
function run_plasmidcc {
    local asm_gfa=$1
    local output_all_smp_dir=$2
    local spe_smp_id=$3

    local smp_exp_dir="$output_all_smp_dir/$spe_smp_id"
    mkdir -p "$smp_exp_dir"

    local database_path
    database_path=$(get_database_file "$spe_smp_id")

    # Run plasmidCC with apptainer
    #
    # The sample results will be in "$smp_exp_dir" directory
    apptainer run -C -B /project -B /scratch -W "$SLURM_TMPDIR" "$app_tainer_img" \
        plasmidCC \
        -i "$asm_gfa" \
        -o "$output_all_smp_dir" \
        -n "$spe_smp_id" \
        -p "$database_path" \
        -D -l 1 -f
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
        spe="Acinetobacter_baumannii"
    elif [[ "$spe_code" == "ecol" ]]; then
        spe="Escherichia_coli"
    elif [[ "$spe_code" == "efae" ]]; then
        spe="Enterococcus_faecium"
    elif [[ "$spe_code" == "paer" ]]; then
        spe="Escherichia_coli"
    elif [[ "$spe_code" == "saur" ]]; then
        spe="Staphylococcus_aureus"
    elif [[ "$spe_code" == "kpne" ]]; then
        spe="Klebsiella_pneumoniae"
    else
        spe="Escherichia_coli"
    fi

    echo "$spe"
}

spe_smp_id=$(get_spe_smp_id)

output_dir="$plasmidcc_outdir/$spe_smp_id"
mkdir -p "$output_dir" 2>/dev/null

uni_data_smp_dir="$uni_data_dir/$spe_smp_id"
gfa_gz="$uni_data_smp_dir/assembly.gfa.gz"
gfa="$output_dir/assembly.gfa"

gunzip -k "$gfa_gz" -c >"$gfa"

#
# Run plasmidCC
#
echo "$SLURM_ARRAY_TASK_ID $spe_smp_id plasmidCC"

run_plasmidcc \
    "$gfa" \
    "$plasmidcc_outdir" \
    "$spe_smp_id"

rm "$gfa"
