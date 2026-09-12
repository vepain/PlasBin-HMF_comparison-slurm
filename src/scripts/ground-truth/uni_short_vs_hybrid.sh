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
# Ground truth of the short-read contigs: label the hybrid assembly contigs, map
# the short contigs on them and label those from what covers them.
# Ported from Tomas Vinar's ground-truth-new-v2.pl (scripts/tvinar-scripts/).
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
# Inputs: the hybrid assembly FASTA, whose Unicycler headers carry the
# circular=/length= tags the labelling needs (the GFA does not have them)
#
short_gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
hybrid_fasta_gz=$(get_unicycler_hybrid_assembly_dir "$smp_uid")/assembly.fasta.gz
#
# Outputs
#
hybrid_labels_csv=$(get_hybrid_labels_csv "$smp_uid")
gt_csv=$(get_gt_csv "$smp_uid")
# Tomas refined the hybrid labels with a mapping against a reference database
# (hybrid.ref.csv). We do not have that database: used only if the file is there.
suppl_csv=$(dirname "$gt_csv")/hybrid.ref.csv

# A sample whose hybrid assembly did not complete has no ground truth: skip it
# without failing the whole array.
for required in "$short_gfa_gz" "$hybrid_fasta_gz"; do
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
awk '/^S/{print ">"$2" length="length($3)"\n"$3}' "$short_gfa" >"$SLURM_TMPDIR/short.fasta"
gunzip -c "$hybrid_fasta_gz" >"$SLURM_TMPDIR/hybrid.fasta"

# minimap2 <target> <query>: the same options as the original script
minimap2 -x map-ont -p 0.8 -c -I 500M --rmq=no --no-long-join -t "$SLURM_CPUS_PER_TASK" \
    "$SLURM_TMPDIR/hybrid.fasta" "$SLURM_TMPDIR/short.fasta" \
    >"$SLURM_TMPDIR/short_vs_hybrid.paf"

python3 "$BENCH_SCRIPTS_DIR/ground-truth/ground_truth.py" \
    --paf "$SLURM_TMPDIR/short_vs_hybrid.paf" \
    --short-gfa "$short_gfa" \
    --hybrid-fasta "$SLURM_TMPDIR/hybrid.fasta" \
    ${suppl_csv:+--supplementary "$suppl_csv"} \
    --out-hybrid-csv "$hybrid_labels_csv" \
    --out-gt-csv "$gt_csv"
