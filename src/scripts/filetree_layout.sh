#!/usr/bin/env bash
# ============================================================================ #
#
# Benchmark file tree layout
#
# ============================================================================ #
BENCH_ROOT_DIR=$1
BENCH_SCRIPTS_DIR="$BENCH_ROOT_DIR/scripts"
BENCH_ENVS_DIR="$BENCH_ROOT_DIR/envs"
BENCH_DATA_DIR="$BENCH_ROOT_DIR/data"

SAMPLES_CSV="$BENCH_DATA_DIR/completed_samples.csv"

# ============================================================================ #
#                            PLASEVAL FORMATTED BINS                           #
# ============================================================================ #
UNI_PLASEVAL_PRED_BINS_DIR="$BENCH_DATA_DIR/data/results/formatted_bins/unicycler/predictions"
UNI_PLASEVAL_GT_BINS_DIR="$BENCH_DATA_DIR/data/results/formatted_bins/unicycler/ground_truths"

# Usage:
#   pred_tsv=$(get_pred_plaseval_fmt "$smp_uid" "$method_code")
function get_pred_plaseval_fmt() {
    local smp_uid=$1     # Sample UID
    local method_code=$2 # Method code
    echo "$UNI_PLASEVAL_PRED_BINS_DIR/$smp_uid.$method_code.tsv"
}

# Usage:
#   gt_tsv=$(get_pred_plaseval_fmt "$smp_uid")
function get_pred_plaseval_fmt() {
    local smp_uid=$1 # Sample UID
    echo "$UNI_PLASEVAL_GT_BINS_DIR/$smp_uid.gt.tsv"
}

# ============================================================================ #
#                                 PLASEVAL-GDV                                 #
# ============================================================================ #
UNI_PLASEVAL_GDV_COMP_DIR="$BENCH_DATA_DIR/data/results/plaseval_gdv/unicycler/comp"

# Usage:
#   base=$UNI_PLASEVAL_GDV_COMP_DIR
#   alpha=0.5
#   dir=$(get_plaseval_comp_alpha_dir "$base" "$alpha")
function get_plaseval_comp_alpha_dir() {
    local base_dir=$1    # PlasEval comp directory
    local alpha_value=$2 # Alpha
    local alpha_dirname="alpha_${alpha_value//./}"
    echo "$base_dir/$alpha_dirname"
}

# Usage:
#   plaseval_out=$(get_plaseval_comp_out "$alpha_dir" "$smp_uid" "$method_code")
function get_plaseval_comp_out() {
    local alpha_dir=$1   # PlasEval comp alpha directory
    local smp_uid=$2     # Sample UID
    local method_code=$3 # Method code
    echo "$alpha_dir/$method_code/${smp_uid}.out"
}

# Usage:
#   plaseval_log=$(get_plaseval_comp_log "$alpha_dir" "$smp_uid" "$method_code")
function get_plaseval_comp_log() {
    local alpha_dir=$1   # PlasEval comp alpha directory
    local smp_uid=$2     # Sample UID
    local method_code=$3 # Method code
    echo "$alpha_dir/$method_code/${smp_uid}.log"
}
