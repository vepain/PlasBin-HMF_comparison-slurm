#!/bin/bash
# ---------------------------------------------------------------------------- #
# Merge PlasEval evaluations.
#
# Usage:
# > bash merge_eval.sh
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

declare -r home_dir="/project/def-chauvec/wg-anoph/benchmarking"
declare -r envs_dir="$home_dir/ENVS"
declare -r merge_script_dir="$home_dir/scripts/merge_plaseval_evaluations"

declare -r samples_tsv="$home_dir/doc/no_unlabeled_samples.tsv"

declare -r plaseval_dir="$home_dir/DATA/RESULTS/EVALUATIONS/UNICYCLER/EVAL"

declare -r merge_dir="$plaseval_dir/MERGED"
mkdir -p "$merge_dir" 2>/dev/null

module load python/3.13
source "$envs_dir/env_merge_plaseval_evaluations/bin/activate"

sopt_meths=()
for str in "${methods[@]}"; do
    sopt_meths+=(-m "$str")
done

python3 "$merge_script_dir/merge_plaseval_evaluations.py" \
    eval "$samples_tsv" "$plaseval_dir" "$merge_dir" \
    "${sopt_meths[@]}"
