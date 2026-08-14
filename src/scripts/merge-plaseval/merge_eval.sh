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
methods=(
    "mob"
    "gpcc_rfpl"
    "pbf_rfpl"
    "pbf_rfpl_filt"
    "pbhmf_rfpl"
    "pbhmf_rfpl_filt"
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
plaseval_dir="$UNI_PLASEVAL_GDV_EVAL_DIR"
merge_dir=$(get_plaseval_eval_merge_dir)
mkdir -p "$merge_dir"

py_script="$BENCH_SCRIPTS_DIR/merge-plaseval/merge_plaseval_evaluations.py"

# FIXME create a TSV file with header:
# sample_uid method_code eval_file

sopt_meths=()
for m in "${methods[@]}"; do
    sopt_meths+=(-m "$m")
done

sopt_evals=()
for m in "${methods[@]}"; do
    eval_dir=$(get_plaseval_eval_meth_dir "$m")
    eval_out=$(get_plaseval_eval_out "$eval_dir" "$smp_uid")
    sopt_evals+=(-e "$m")
done

# ---------------------------------------------------------------------------- #
# Merging
# ---------------------------------------------------------------------------- #
python3 "$py_script" \
    eval "$SAMPLES_CSV" "$merge_dir" \
    "${sopt_meths[@]}" \
    "${sopt_evals[@]}"
