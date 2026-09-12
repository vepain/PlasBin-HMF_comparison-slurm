#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script for job resubmission on our clusters.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=3:00:00
# minimap2 on two bacterial assemblies takes seconds
#SBATCH --array=2-1242
#SBATCH --output=logs/%x/%A/%a.out
#SBATCH --error=logs/%x/%A/%a.err
# ---------------------------------------------------------------------------- #
# Ground truth of the short-read contigs: map them on the hybrid assembly contigs
# and carry over each hybrid contig's chromosome/plasmid label.
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/minimap2.sh
source "$BENCH_ENVS_DIR/minimap2.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
smp_uid=$(get_sample_uid_from_slurm_array "$SAMPLES_CSV")
#
# Inputs
#
short_gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
hybrid_gfa_gz=$(get_unicycler_hybrid_assembly_dir "$smp_uid")/assembly.gfa.gz
hybrid_labels_csv=$(get_hybrid_labels_csv "$smp_uid")
#
# Outputs
#
gt_csv=$(get_gt_csv "$smp_uid")

# A sample whose hybrid assembly did not complete has no ground truth: skip it
# without failing the whole array.
for required in "$short_gfa_gz" "$hybrid_gfa_gz" "$hybrid_labels_csv"; do
    if [[ ! -f "$required" ]]; then
        echo "$smp_uid: missing $required, skipping"
        exit 0
    fi
done

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$(dirname "$gt_csv")")"

# ---------------------------------------------------------------------------- #
# Mapping the short contigs on the hybrid contigs
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid ground truth"

short_gfa="$SLURM_TMPDIR/short.gfa"
gunzip -c "$short_gfa_gz" >"$short_gfa"
awk '/^S/{print ">"$2"\n"$3}' "$short_gfa" >"$SLURM_TMPDIR/short.fasta"
gunzip -c "$hybrid_gfa_gz" | awk '/^S/{print ">"$2"\n"$3}' >"$SLURM_TMPDIR/hybrid.fasta"

# minimap2 <target> <query>: the PAF query is the short contig, as in Tomas' files
minimap2 -c -x asm5 -t "$SLURM_CPUS_PER_TASK" \
    "$SLURM_TMPDIR/hybrid.fasta" "$SLURM_TMPDIR/short.fasta" \
    >"$SLURM_TMPDIR/short_vs_hybrid.paf"

python3 "$BENCH_SCRIPTS_DIR/ground-truth/gt_from_paf.py" \
    --paf "$SLURM_TMPDIR/short_vs_hybrid.paf" \
    --short-gfa "$short_gfa" \
    --hybrid-labels "$hybrid_labels_csv" \
    --out "$gt_csv"
