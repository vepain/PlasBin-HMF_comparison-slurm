#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script (single job, no array) — aggregate PlasEval comp results.
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=3:00:00
#SBATCH --output=logs/merge_comp/%j.out
#SBATCH --error=logs/merge_comp/%j.err
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r alpha=0.5 # must match the comp_uni.sh run
methods=(
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
# shellcheck source=../../envs/py-tools.sh
source "$BENCH_ENVS_DIR/py-tools.sh"

# ---------------------------------------------------------------------------- #
# Set arguments
# ---------------------------------------------------------------------------- #
plaseval_dir=$(get_plaseval_comp_alpha_dir "$UNI_PLASEVAL_GDV_COMP_DIR" "$alpha")
merge_dir=$(get_plaseval_comp_merge_dir "$alpha")
mkdir -p "$merge_dir"

py_script="$BENCH_SCRIPTS_DIR/merge-plaseval/merge_plaseval_evaluations.py"

sopt_meths=()
for m in "${methods[@]}"; do
    sopt_meths+=(-m "$m")
done

# ---------------------------------------------------------------------------- #
# Merging
# ---------------------------------------------------------------------------- #
python3 "$py_script" \
    comp "$SAMPLES_CSV" "$plaseval_dir" "$merge_dir" \
    "${sopt_meths[@]}"
