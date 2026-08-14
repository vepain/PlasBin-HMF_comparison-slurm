#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-1242
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# Run RFPlasmid on Unicycler assemblies to get the contig plasmidness.
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/rfplasmids.sh
source "$BENCH_ENVS_DIR/rfplasmids.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")

gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
output_dir=$(get_rfplasmid_out_dir "$smp_uid")

# RFPlasmid consumes a directory of FASTA files; build it from the GFA segments.
input_dir="$SLURM_TMPDIR/$smp_uid"
mkdir -p "$input_dir"
gunzip -c "$gfa_gz" | awk '/^S/{print ">"$2"\n"$3}' >"$input_dir/assembly.fasta"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$output_dir"

# ---------------------------------------------------------------------------- #
# Running RFPlasmid
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid rfplasmid"

mkdir -p "$output_dir"

# TODO: confirm --species (or use "generic") against the installed RFPlasmid.
apptainer run -C -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    rfplasmid \
    --species generic \
    --input "$input_dir" \
    --threads "$SLURM_CPUS_PER_TASK" \
    --out "$output_dir"
