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
smp_uid=$(get_sample_uid_from_slurm_array "$ONLY_LABELLED_SAMPLES_TSV")
species_id=$(get_tsv_cell_from_slurm_array "$ONLY_LABELLED_SAMPLES_TSV" "species_id")

# RFPlasmid model per species. There is no Acinetobacter model, so A. baumannii
# falls back to Generic. Model names are capitalized as in RFPlasmid's --species list.
case "$species_id" in
    ecol | kpne) rfpl_species="Enterobacteriaceae" ;;
    efae) rfpl_species="Enterococcus" ;;
    saur) rfpl_species="Staphylococcus" ;;
    paer) rfpl_species="Pseudomonas" ;;
    abau) rfpl_species="Generic" ;;
    *)
        echo "No RFPlasmid model mapped for species '$species_id'" >&2
        exit 1
        ;;
esac

gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
output_dir=$(get_rfplasmid_out_dir "$smp_uid")

# RFPlasmid consumes a directory of FASTA files; build it from the GFA segments.
input_dir="$SLURM_TMPDIR/$smp_uid"
mkdir -p "$input_dir"
gunzip -c "$gfa_gz" | awk '/^S/{print ">"$2"\n"$3}' >"$input_dir/assembly.fasta"

# ---------------------------------------------------------------------------- #
# Register the job id
# ---------------------------------------------------------------------------- #
register_job_id "$(dirname "$output_dir")"

# ---------------------------------------------------------------------------- #
# Running RFPlasmid
# ---------------------------------------------------------------------------- #
echo "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ($SLURM_JOB_ID) $smp_uid rfplasmid $rfpl_species"

# Do not create "$output_dir": RFPlasmid creates it, and if it already exists it
# writes to "${output_dir}_<timestamp>" instead, which nothing downstream reads.
#
# --jelly: jellyfish k-mer counting, which RFPlasmid strongly recommends (the
# Python fallback is slow); jellyfish ships in the image.
# PYTHONUNBUFFERED: RFPlasmid's progress lines reach the log as they happen instead
# of only at exit, so a killed task still shows how far it got.
apptainer run -C -B "$SLURM_TMPDIR" -W "$SLURM_TMPDIR" --env PYTHONUNBUFFERED=1 "$APPTAINER_IMG" \
    --species "$rfpl_species" \
    --jelly \
    --input "$input_dir" \
    --threads "$SLURM_CPUS_PER_TASK" \
    --out "$output_dir"
