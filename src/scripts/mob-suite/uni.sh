#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=2-837
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r METHOD_CODE="mob"
# ---------------------------------------------------------------------------- #
# Run MOB-recon plasmid binning on Unicycler assemblies.
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/mob-suite.sh
source "$BENCH_ENVS_DIR/mob-suite.sh"
# requires ${BENCH_ENVS_DIR}/mob-suite.sif already built (its databases are baked in)

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$ONLY_LABELLED_SAMPLES_TSV")
#
# Inputs
#
gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")

# MOB-recon reads an uncompressed FASTA: build it from the GFA segments, so the
# contig_id column of contig_report.txt is the GFA segment name.
fasta="$SLURM_TMPDIR/$smp_uid.fasta"
gunzip -c "$gfa_gz" | awk '/^S/{print ">"$2"\n"$3}' >"$fasta"
#
# Outputs (MOB-recon writes contig_report.txt there, see get_mob_bin_pred)
#
output_dir=$(get_uni_bin_dir "$smp_uid" "$METHOD_CODE")

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running MOB-recon
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid $METHOD_CODE"

# Do not create "$output_dir": MOB-recon refuses an existing --outdir. Its --force
# would rmtree the directory instead, so a resubmitted sample fails loudly until its
# directory is deleted by hand.
apptainer run -C -B "$SLURM_TMPDIR" -W "$SLURM_TMPDIR" "$APPTAINER_IMG" \
    mob_recon \
    --infile "$fasta" \
    --outdir "$output_dir" \
    --database_directory "$MOB_DB_DIR" \
    --num_threads "$SLURM_CPUS_PER_TASK"
