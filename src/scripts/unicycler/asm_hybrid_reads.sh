#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-561
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# Assemble a sample with Unicycler in hybrid mode (Illumina + long reads),
# downloading both read sets from the SRA.
# ---------------------------------------------------------------------------- #
# Abort the task on the first failure: a read set that fails to download must not
# reach Unicycler as a missing input and report success
# ---------------------------------------------------------------------------- #
set -e

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/unicycler.sh
source "$BENCH_ENVS_DIR/unicycler.sh"
# requires ${BENCH_ENVS_DIR}/unicycler.sif already built

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SRA_SAMPLES_TSV")
#
# Inputs
#
sra_sr_id=$(get_tsv_cell_from_slurm_array "$SRA_SAMPLES_TSV" "sra_sr")
sra_lr_id=$(get_tsv_cell_from_slurm_array "$SRA_SAMPLES_TSV" "sra_lr")

# The reads are only Unicycler's input: stage them on the node-local disk,
# which SLURM wipes at the end of the task. They stay uncompressed -- gzipping a
# file we are about to delete only makes Unicycler decompress it again.
reads_dir="$SLURM_TMPDIR/reads"
fastq_1="$reads_dir/${sra_sr_id}_1.fastq"
fastq_2="$reads_dir/${sra_sr_id}_2.fastq"
fastq_lr="$reads_dir/${sra_lr_id}.fastq"
#
# Outputs
#
output_dir=$(get_unicycler_hybrid_assembly_dir "$smp_uid")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running Unicycler
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $sra_sr_id $sra_lr_id"

mkdir -p "$output_dir" "$reads_dir"

#
# Download the short and the long reads
# fasterq-dump is the multi-threaded replacement for fastq-dump; it keeps the
# same _1/_2 (paired) and bare (single) output naming
#
prefetch "$sra_sr_id" --output-directory "$reads_dir"
fasterq-dump --threads "$SLURM_CPUS_PER_TASK" --temp "$SLURM_TMPDIR" \
    --outdir "$reads_dir" "$reads_dir/$sra_sr_id"

prefetch "$sra_lr_id" --output-directory "$reads_dir"
fasterq-dump --threads "$SLURM_CPUS_PER_TASK" --temp "$SLURM_TMPDIR" \
    --outdir "$reads_dir" "$reads_dir/$sra_lr_id"

#
# Hybrid assembly
#
apptainer run -C -B "$SLURM_TMPDIR" -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    unicycler \
    -1 "$fastq_1" \
    -2 "$fastq_2" \
    -l "$fastq_lr" \
    -o "$output_dir" \
    -t "$SLURM_CPUS_PER_TASK"

gzip -f "$output_dir/assembly.fasta" "$output_dir/assembly.gfa"
