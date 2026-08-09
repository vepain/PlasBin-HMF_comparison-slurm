#!/bin/bash
# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r alpha=0.5
# ---------------------------------------------------------------------------- #
# Merge PlasEval evaluations.
#
# Usage:
# > bash merge_comp.sh
# ---------------------------------------------------------------------------- #
# User variable
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

umask 007

home_dir="/project/def-chauvec/wg-anoph/benchmarking"
envs_dir="$home_dir/ENVS"
merge_script_dir="$home_dir/scripts/merge_plaseval_evaluations"

samples_tsv="$home_dir/doc/no_unlabeled_samples.tsv"

alpha_dir="ALPHA_${alpha//./}"
plaseval_dir="$home_dir/DATA/RESULTS/EVALUATIONS/UNICYCLER/COMP/$alpha_dir"

merge_dir="$plaseval_dir/MERGED"
mkdir -p "$merge_dir" 2>/dev/null

module load python/3.13
source "$envs_dir/env_merge_plaseval_evaluations/bin/activate"

sopt_meths=()
for str in "${methods[@]}"; do
    sopt_meths+=(-m "$str")
done

python3 "$merge_script_dir/merge_plaseval_evaluations.py" \
    comp "$samples_tsv" "$plaseval_dir" "$merge_dir" \
    "${sopt_meths[@]}"
