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

SAMPLES_CSV="$BENCH_ROOT_DIR/completed_samples.csv"

# ============================================================================ #
#                                 GROUND TRUTH                                 #
# ============================================================================ #
GROUND_TRUTH_DIR="$BENCH_DATA_DIR/ground_truths"

# Usage:
#   gt_csv=$(get_gt_csv "$smp_uid")
function get_gt_csv() {
    local smp_uid=$1
    echo "$GROUND_TRUTH_DIR/$smp_uid/short.gfa.csv"
}

# ============================================================================ #
#                              UNICYCLER ASSEMBLY INPUT                        #
# ============================================================================ #
UNI_ASSEMBLY_DIR="$BENCH_DATA_DIR/assembly_files/unicycler"

# Usage:
#   gfa_gz=$(get_unicycler_assembly_gfa_gz "$smp_uid")
function get_unicycler_assembly_gfa_gz() {
    local smp_uid=$1
    echo "$UNI_ASSEMBLY_DIR/$smp_uid/assembly.gfa.gz"
}

# ============================================================================ #
#                                CLASSIFICATION                                #
# ============================================================================ #
# ---------------------------------------------------------------------------- #
#                                   RFPlasmid                                  #
# ---------------------------------------------------------------------------- #
UNI_RFPLASMID_DIR="$BENCH_DATA_DIR/results/rfplasmid/unicycler"

# Usage:
#   dir=$(get_rfplasmid_out_dir "$smp_uid")
function get_rfplasmid_out_dir() {
    local smp_uid=$1
    echo "$UNI_RFPLASMID_DIR/$smp_uid"
}

# ---------------------------------------------------------------------------- #
#                                    Platon                                    #
# ---------------------------------------------------------------------------- #
UNI_PLATON_DIR="$BENCH_DATA_DIR/results/platon/unicycler"

function get_platon_out_dir() {
    local _smp_uid=$1
    echo "$UNI_PLATON_DIR/$_smp_uid"
}

# ---------------------------------------------------------------------------- #
#                         Formatted PlasBin-flow Input                         #
# ---------------------------------------------------------------------------- #
UNI_FORMATTED_INPUT_DIR="$BENCH_DATA_DIR/results/formatted_input/unicycler"

# RFPlasmid plasmidness scores in PBf format.
# Usage:
#   plm_tsv=$(get_plm_pbf_rfpl_tsv "$smp_uid")
function get_plm_pbf_rfpl_tsv() {
    local smp_uid=$1
    echo "$UNI_FORMATTED_INPUT_DIR/rfplasmid/input_pbf/${smp_uid}_scores.tsv"
}

# Platon seed contigs in PBf format.
# Usage:
#   seeds_tsv=$(get_seeds_pbf_platon_tsv "$smp_uid")
function get_seeds_pbf_platon_tsv() {
    local smp_uid=$1
    echo "$UNI_FORMATTED_INPUT_DIR/platon/input_pbf/${smp_uid}_seeds.tsv"
}

# ============================================================================ #
#                                   BINNING                                    #
# ============================================================================ #
UNI_BIN_DIR="$BENCH_DATA_DIR/results/binning/unicycler"

# Per-method binning directory (has bins.tsv, bins_filt.tsv, ...).
# Usage:
#   bin_dir=$(get_uni_bin_dir "$smp_uid" "$method_code")
function get_uni_bin_dir() {
    local smp_uid=$1
    local method_code=$2
    echo "$UNI_BIN_DIR/$method_code/$smp_uid"
}

# ---------------------------------------------------------------------------- #
#                                      Pbf                                     #
# ---------------------------------------------------------------------------- #
function get_pbf_bin_pred() {
    local _smp_uid=$1
    local _method_code=$2
    echo "$(get_uni_bin_dir "$_smp_uid" "$_method_code")/bins.tsv"
}

# ---------------------------------------------------------------------------- #
#                                     PBHMF                                    #
# ---------------------------------------------------------------------------- #
function get_pbhmf_pbf_bin_pred() {
    local _smp_uid=$1
    local _method_code=$2
    echo "$(get_uni_bin_dir "$_smp_uid" "$_method_code")/plasbin_flow_bins.tsv"
}

# ---------------------------------------------------------------------------- #
#                                     Gpcc                                     #
# ---------------------------------------------------------------------------- #
function get_gpcc_bin_pred() {
    local _smp_uid=$1
    local _method_code=$2
    echo "$(get_uni_bin_dir "$_smp_uid" "$_method_code")/bins.tab"
}

# ---------------------------------------------------------------------------- #
#                                      Mob                                     #
# ---------------------------------------------------------------------------- #
function get_mob_bin_pred() {
    local smp_uid=$1
    local method_code=$2
    echo "$(get_uni_bin_dir "$smp_uid" "$method_code")/contig_report.txt"
}

# ============================================================================ #
#                            PLASEVAL FORMATTED BINS                           #
# ============================================================================ #
UNI_PLASEVAL_PRED_BINS_DIR="$BENCH_DATA_DIR/results/formatted_bins/unicycler/predictions"
UNI_PLASEVAL_GT_BINS_DIR="$BENCH_DATA_DIR/results/formatted_bins/unicycler/ground_truths"

# Usage:
#   pred_tsv=$(get_pred_plaseval_fmt "$smp_uid" "$method_code")
function get_pred_plaseval_fmt() {
    local smp_uid=$1     # Sample UID
    local method_code=$2 # Method code
    echo "$UNI_PLASEVAL_PRED_BINS_DIR/$method_code/$smp_uid.tsv"
}

# Usage:
#   gt_tsv=$(get_gt_plaseval_fmt "$smp_uid")
function get_gt_plaseval_fmt() {
    local smp_uid=$1 # Sample UID
    echo "$UNI_PLASEVAL_GT_BINS_DIR/$smp_uid.tsv"
}

# ============================================================================ #
#                                 REPEAT STATS                                 #
# ============================================================================ #
UNI_REPEAT_STATS_GT_TSV="$BENCH_DATA_DIR/results/repeat_stats/unicycler/ground_truths.tsv"

# ============================================================================ #
#                                 PLASEVAL-GDV  (COMP)                         #
# ============================================================================ #
UNI_PLASEVAL_GDV_COMP_DIR="$BENCH_DATA_DIR/results/plaseval_gdv/unicycler/comp"

function get_plaseval_comp_alpha_dir() {
    local alpha_value=$1 # Alpha
    echo "$UNI_PLASEVAL_GDV_COMP_DIR/alpha_${alpha_value//./}"
}

# Usage:
#   alpha=0.5
#   method_code="pbf_rfpl"
#   dir=$(get_plaseval_comp_alpha_meth_dir "$alpha" "$method_code")
function get_plaseval_comp_alpha_meth_dir() {
    local alpha_value=$1 # Alpha
    local method_code=$2
    echo "$(get_plaseval_comp_alpha_dir "$alpha_value")/$method_code"
}

# Usage:
#   plaseval_out=$(get_plaseval_comp_out "$comp_dir" "$smp_uid")
function get_plaseval_comp_out() {
    local comp_dir=$1 # PlasEval comp alpha directory
    local smp_uid=$2  # Sample UID
    echo "$comp_dir/${smp_uid}.out"
}

# Usage:
#   plaseval_log=$(get_plaseval_comp_log "$comp_dir" "$smp_uid")
function get_plaseval_comp_log() {
    local comp_dir=$1 # PlasEval comp alpha directory
    local smp_uid=$2  # Sample UID
    echo "$comp_dir/${smp_uid}.log"
}

# ============================================================================ #
#                                 PLASEVAL-GDV  (EVAL)                         #
# ============================================================================ #
UNI_PLASEVAL_GDV_EVAL_DIR="$BENCH_DATA_DIR/results/plaseval_gdv/unicycler/eval"

# Usage:
#   method_code="pbf_rfpl"
#   dir=$(get_plaseval_eval_meth_dir "$method_code")
function get_plaseval_eval_meth_dir() {
    local method_code=$1 # Method code
    echo "$UNI_PLASEVAL_GDV_EVAL_DIR/$method_code"
}

# Usage:
#   plaseval_out=$(get_plaseval_eval_out "$eval_dir" "$smp_uid")
function get_plaseval_eval_out() {
    local eval_dir=$1 # PlasEval comp alpha directory
    local smp_uid=$2  # Sample UID
    echo "$eval_dir/${smp_uid}.out"
}

# Usage:
#   plaseval_log=$(get_plaseval_eval_log "$eval_dir" "$smp_uid")
function get_plaseval_eval_log() {
    local eval_dir=$1 # PlasEval comp alpha directory
    local smp_uid=$2  # Sample UID
    echo "$eval_dir/${smp_uid}.log"
}

# ============================================================================ #
#                               MERGED PLASEVAL REPORTS                        #
# ============================================================================ #
# Usage:
#   merge_dir=$(get_plaseval_eval_merge_dir)
function get_plaseval_eval_merge_dir() {
    echo "$UNI_PLASEVAL_GDV_EVAL_DIR/merged"
}

# Usage:
#   merge_dir=$(get_plaseval_comp_merge_dir "$alpha")
function get_plaseval_comp_merge_dir() {
    local alpha_value=$1
    echo "$(get_plaseval_comp_alpha_dir "$alpha_value")/merged"
}

# ============================================================================ #
#                              SAMPLE PROPERTIES                               #
# ============================================================================ #
# Usage:
#   min_len=$(get_min_len "$smp_uid")
function get_min_len() {
    local smp_uid=$1
    echo ""
}
