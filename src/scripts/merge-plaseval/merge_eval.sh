#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script (single job, no array) — aggregate PlasEval eval results.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=3:00:00
#SBATCH --output=logs/%x/%j.out
#SBATCH --error=logs/%x/%j.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
method_codes=(
    "mob"
    "gpcc_rfpl"
    "pbf_rfpl"
    "pbf_rfpl_filt"
    "pbhmf_rfpl"
    "pbhmf_rfpl_filt"
    "pbhmf_rfpl_recomb26"
    "pbhmf_rfpl_recomb26_filt"
)
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                                  Environment                                 #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/merge-plaseval.sh
source "$BENCH_ENVS_DIR/merge-plaseval.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
#
# Create the temp TSV file
#
tmp_tsv="$SLURM_TMPDIR/comp.tsv"

# Write header
printf "species_id\tsample_uid\tmethod_code\teval_file\n" >"$tmp_tsv"

# Get species_id/sample_id tuples via utils.sh
mapfile -t sample_tuples < <(get_sample_tuples "$SAMPLES_TSV")

# Loop over methods and sample tuples
for m in "${method_codes[@]}"; do
    eval_dir=$(get_plaseval_eval_meth_dir "$m")
    for tuple in "${sample_tuples[@]}"; do
        IFS=$'\t' read -r species_id sample_id <<<"$tuple"
        smp_uid=$(get_sample_uid "$species_id" "$sample_id")
        eval_out=$(get_plaseval_eval_out "$eval_dir" "$smp_uid")
        printf "%s\t%s\t%s\t%s\n" "$species_id" "$smp_uid" "$m" "$eval_out" >>"$tmp_tsv"
    done
done
# ---------------------------------------------------------------------------- #
#                                  Set Outputs                                 #
# ---------------------------------------------------------------------------- #
merge_dir=$(get_plaseval_eval_merge_dir)
mkdir -p "$merge_dir"

py_script="$BENCH_SCRIPTS_DIR/merge-plaseval/merge_plaseval_evaluations.py"

# ---------------------------------------------------------------------------- #
# Merging
# ---------------------------------------------------------------------------- #
python3 "$py_script" \
    eval "$tmp_tsv" "$merge_dir"
