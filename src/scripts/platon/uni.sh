#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=3:00:00
#SBATCH --array=2-837
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# Run Platon on Unicycler assemblies to classify contigs as plasmid or chromosome.
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/platon.sh
source "$BENCH_ENVS_DIR/platon.sh"
# requires ${BENCH_ENVS_DIR}/Platon.sif already built (its database is baked in)

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$ONLY_LABELLED_SAMPLES_TSV")
#
# Inputs
#
gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")

# Platon consumes a FASTA: build it from the GFA segments so the contig names are
# the GFA ones. Platon names its outputs after this file (<smp_uid>.tsv, ...).
fasta="$SLURM_TMPDIR/$smp_uid.fasta"
gunzip -c "$gfa_gz" | awk '/^S/{print ">"$2"\n"$3}' >"$fasta"
#
# Outputs
#
output_dir=$(get_platon_out_dir "$smp_uid")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running Platon
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid platon"

mkdir -p "$output_dir"

apptainer run -C -B "$SLURM_TMPDIR" -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    --output "$output_dir" \
    --threads "$SLURM_CPUS_PER_TASK" \
    --verbose \
    "$fasta"
