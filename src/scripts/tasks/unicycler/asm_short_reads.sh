#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-561
#SBATCH --output=logs/asm_short_reads/%A/%a.out
#SBATCH --error=logs/asm_short_reads/%A/%a.err

# ---------------------------------------------------------------------------- #
# User variables
# ---------------------------------------------------------------------------- #
declare -r samples_tsv="/project/6001426/wg-anoph/benchmarking/2026_Plasmid_Binning_Bench/hyplas_samples/hyplas_samples.tsv"
declare -r all_samples_outdir="/project/6001426/wg-anoph/benchmarking/2026_Plasmid_Binning_Bench/hyplas_samples/data/assembly/short_reads/unicycler"

declare -r env_script="/project/6001426/wg-anoph/benchmarking/2026_Plasmid_Binning_Bench/hyplas_samples/envs/unicycler.sh"
# ---------------------------------------------------------------------------- #

umask 007

# Sample list column names
declare -r smp_uid_col="sample_uid"
declare -r sra_sr_col="sra_sr"

# Get species and sample UID
#
# Arguments:
# 1. Samples file
#
# Usage:
#   > spe_smp_id=$(get_sample_uid_from_slurm_array "$samples_file")
function get_sample_uid_from_slurm_array {
    local smp_file=$1
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
}

# Get cell value
#
# Arguments:
# 1. row_number (starts at 1)
# 2. column name
# 3. samples_tsv
#
# Usage:
#   > cell_val=$(get_samples_tsv_cell "$row_number" "$column_name" "$samples_tsv")
function get_samples_tsv_cell {
    local row_line=$1
    local col_name=$2
    local samples_tsv=$3

    local col_idx
    col_idx=$(awk -v RS='\t' "/^${col_name}/{print NR; exit}" "${samples_tsv}")

    sed -n "${row_line}"p "${samples_tsv}" | cut -f"${col_idx}"
}

# Run unicycler
#
# Arguments:
# 1. Sample result output directory
# 2. SRR ID for short reads
#
# Usage:
#   > run_sample "$smp_outdir" "$sra_sr_id"
function run_uni_sr {
    local smp_outdir=$1
    local sra_sr_id=$2

    mkdir -p "$smp_outdir"

    local reads_dir="$smp_outdir/reads"
    mkdir -p "$reads_dir"

    "${SRA_TOOLS_CMD_PREFIX[@]}" prefetch "$sra_sr_id" --output-directory "$reads_dir"
    "${SRA_TOOLS_CMD_PREFIX[@]}" fastq-dump --split-3 --outdir "$reads_dir" "$reads_dir/$sra_sr_id"

    local fastq_1="$reads_dir/${sra_sr_id}_1.fastq"
    local fastq_2="$reads_dir/${sra_sr_id}_2.fastq"

    gzip -f "$fastq_1"
    local fastq_1_gz="${fastq_1}.gz"
    gzip -f "$fastq_2"
    local fastq_2_gz="${fastq_2}.gz"

    "${UNICYCLER_CMD_PREFIX[@]}" unicycler -1 "$fastq_1_gz" -2 "$fastq_2_gz" -o "$smp_outdir"

    gzip -f "$smp_outdir/assembly.fasta"
    gzip -f "$smp_outdir/assembly.gfa"

    rm -rf "$reads_dir"
}

# ---------------------------------------------------------------------------- #
# Load environment script
# ---------------------------------------------------------------------------- #
source "$env_script"

# ---------------------------------------------------------------------------- #
# Run
# ---------------------------------------------------------------------------- #
mkdir -p "$all_samples_outdir"

row_line="${SLURM_ARRAY_TASK_ID}"

smp_uid=$(get_samples_tsv_cell "$row_line" "$smp_uid_col" "$samples_tsv")
sra_sr_id=$(get_samples_tsv_cell "$row_line" "$sra_sr_col" "$samples_tsv")

smp_outdir="$all_samples_outdir/$smp_uid"

echo "----------------------------------------"
echo "Running Unicycler"
echo "----------------------------------------"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Job ID: ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo
echo "Sample UID: $smp_uid"
echo "SRR ID: $sra_sr_id"
echo "----------------------------------------"
echo

run_uni_sr "$smp_outdir" "$sra_sr_id"
# ---------------------------------------------------------------------------- #
