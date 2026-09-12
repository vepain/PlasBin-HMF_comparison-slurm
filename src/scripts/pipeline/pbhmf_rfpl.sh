#!/usr/bin/env bash
# ============================================================================ #
#
# Launch the PlasBin-HMF (+ RFPlasmid) pipeline as chained sbatch jobs.
#
# Run it on a login node, from the directory that should hold the logs (each
# step logs to ./logs/<job name>/). Every step's script is copied into
# ./pipeline_<date>/ with its user variables set, then submitted with a
# dependency on the steps it reads from.
#
# Usage:
#   > ./pbhmf_rfpl.sh [first_step]
#   first_step: assembly (default) | classification | format | binning | evaluation
#
# Set ARRAY to restrict the per-sample steps to some array indices, e.g. for a test run:
#   > ARRAY=2,253,374 ./pbhmf_rfpl.sh binning
# The merges read every sample, so in such a run they are cancelled: that is expected.
#
# ============================================================================ #

# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r METHOD_CODE="pbhmf_rfpl"
declare -r ALPHA=0.5 # PlasEval comp parameter (comp_uni.sh and merge_comp.sh)
declare -r FIRST_STEP="${1:-assembly}"
declare -r ARRAY="${ARRAY:-}" # array indices for the per-sample steps; empty = the script's own

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

set -euo pipefail

case "$FIRST_STEP" in
assembly) first=1 ;;
classification) first=2 ;;
format) first=3 ;;
binning) first=4 ;;
evaluation) first=5 ;;
*)
    echo "Unknown first step '$FIRST_STEP' (assembly|classification|format|binning|evaluation)" >&2
    exit 1
    ;;
esac

RUN_DIR="$PWD/pipeline_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RUN_DIR"

# ---------------------------------------------------------------------------- #
# Helpers
# ---------------------------------------------------------------------------- #
# Usage: script=$(prep <job name> <script path under scripts/>)
function prep() {
    cp "$BENCH_SCRIPTS_DIR/$2" "$RUN_DIR/$1.sh"
    echo "$RUN_DIR/$1.sh"
}

# Rewrite the user variable line `declare -r <name>=...` of a script copy
# Usage: set_var <script> <name> <value>
function set_var() {
    awk -v n="$2" -v v="$3" \
        '$0 ~ "^declare -r " n "=" {print "declare -r " n "=\"" v "\""; next} {print}' \
        "$1" >"$1.tmp" && mv "$1.tmp" "$1"
}

# Rewrite the multi-line array `<name>=( ... )` of a script copy
# Usage: set_array <script> <name> <values...>
function set_array() {
    local script=$1 name=$2
    shift 2
    awk -v n="$name" -v v="$*" '
        skip { if ($0 ~ /^\)/) skip = 0; next }
        $0 ~ "^" n "=\\(" {
            k = split(v, a, " "); printf "%s=(", n
            for (i = 1; i <= k; i++) printf " \"%s\"", a[i]
            print " )"; skip = 1; next
        }
        { print }' "$script" >"$script.tmp" && mv "$script.tmp" "$script"
}

# "<type>:<id>:<id>", or nothing when no upstream job was launched (first step)
# Usage: dependency=$(dep <type> <job ids...>)
function dep() {
    local type=$1 ids="" id
    shift
    for id in "$@"; do
        if [[ -n "$id" ]]; then ids+=":$id"; fi
    done
    if [[ -n "$ids" ]]; then echo "$type$ids"; fi
}

# Submit a script copy; prints its job id and records it in $RUN_DIR/jobs.tsv.
# --kill-on-invalid-dep: a task whose upstream failed is cancelled, not left pending.
# Usage: id=$(submit <job name> <dependency, may be empty> <script copy>)
function submit() {
    local id array_opt=""
    # only the per-sample steps have an #SBATCH --array line; the merges must stay single jobs
    if [[ -n "$ARRAY" ]] && grep -q '^#SBATCH --array=' "$3"; then
        array_opt="--array=$ARRAY"
    fi
    id=$(sbatch --parsable --job-name="$1" --kill-on-invalid-dep=yes $array_opt \
        ${2:+--dependency="$2"} "$3" | cut -d';' -f1)
    printf '%s\t%s\t%s\n' "$1" "$id" "${2:--}" | tee -a "$RUN_DIR/jobs.tsv" >&2
    echo "$id"
}

echo "Launching from '$FIRST_STEP'; submitted scripts in $RUN_DIR" >&2
asm_id="" rfpl_id="" fmt_id="" bin_id="" filt_id=""

# ---------------------------------------------------------------------------- #
# 1. Short-read assembly: 1241 samples ($SAMPLES_CSV) against the 836 labelled
#    ones downstream, so array indices do not match: classification waits for the
#    whole array (afterany: a failed assembly only fails that sample downstream).
# ---------------------------------------------------------------------------- #
if ((first <= 1)); then
    asm_id=$(submit asm-short "" "$(prep asm-short unicycler/asm_short_reads.sh)")
fi

# ---------------------------------------------------------------------------- #
# 2. RFPlasmid classification
# ---------------------------------------------------------------------------- #
if ((first <= 2)); then
    rfpl_id=$(submit rfplasmid "$(dep afterany "$asm_id")" "$(prep rfplasmid rfplasmid/uni.sh)")
fi

# From here on every step runs over the same 836 labelled samples: task i waits
# only for task i of the steps it reads from (aftercorr).

# ---------------------------------------------------------------------------- #
# 3. RFPlasmid -> PB-HMF plasmidness and seeds
# ---------------------------------------------------------------------------- #
if ((first <= 3)); then
    fmt_id=$(submit format-pbhmf-input "$(dep aftercorr "$rfpl_id")" \
        "$(prep format-pbhmf-input format-pbhmf-input/rfpl_uni.sh)")
fi

# ---------------------------------------------------------------------------- #
# 4. PlasBin-HMF binning, then the filtered bins (${METHOD_CODE}_filt)
# ---------------------------------------------------------------------------- #
if ((first <= 4)); then
    script=$(prep "$METHOD_CODE" plasbin-hmf/rfpl_uni.sh)
    set_var "$script" METHOD_CODE "$METHOD_CODE"
    bin_id=$(submit "$METHOD_CODE" "$(dep aftercorr "$fmt_id")" "$script")

    script=$(prep "filter-$METHOD_CODE" filter_bins/filter_bins.sh)
    set_var "$script" METHOD_CODE "$METHOD_CODE"
    set_var "$script" METHOD_TOOL pbhmf
    filt_id=$(submit "filter-$METHOD_CODE" "$(dep aftercorr "$bin_id")" "$script")
fi

# ---------------------------------------------------------------------------- #
# 5. Evaluation of both bin sets, then the merged reports
# ---------------------------------------------------------------------------- #
gt_id=$(submit format-gt "" "$(prep format-gt format-plaseval/gt_uni.sh)")

eval_ids=()
comp_ids=()
for m in "$METHOD_CODE" "${METHOD_CODE}_filt"; do
    if [[ "$m" == "$METHOD_CODE" ]]; then upstream=$bin_id; else upstream=$filt_id; fi

    script=$(prep "pred-$m" format-plaseval/pred_uni.sh)
    set_var "$script" METHOD_CODE "$m"
    set_var "$script" METHOD_FORMAT pbhmf
    pred_id=$(submit "pred-$m" "$(dep aftercorr "$upstream")" "$script")

    script=$(prep "eval-$m" plaseval-gdv/eval.sh)
    set_var "$script" METHOD_CODE "$m"
    eval_ids+=("$(submit "eval-$m" "$(dep aftercorr "$pred_id" "$gt_id")" "$script")")

    script=$(prep "comp-$m" plaseval-gdv/comp_uni.sh)
    set_var "$script" METHOD_CODE "$m"
    set_var "$script" ALPHA "$ALPHA"
    comp_ids+=("$(submit "comp-$m" "$(dep aftercorr "$pred_id" "$gt_id")" "$script")")
done

# Merges need every sample: they only run if all eval/comp tasks succeeded
script=$(prep merge-eval merge-plaseval/merge_eval.sh)
set_array "$script" method_codes "$METHOD_CODE" "${METHOD_CODE}_filt"
submit merge-eval "$(dep afterok "${eval_ids[@]}")" "$script" >/dev/null

script=$(prep merge-comp merge-plaseval/merge_comp.sh)
set_array "$script" METHOD_CODES "$METHOD_CODE" "${METHOD_CODE}_filt"
set_var "$script" ALPHA "$ALPHA"
submit merge-comp "$(dep afterok "${comp_ids[@]}")" "$script" >/dev/null

echo "Cancel everything: scancel $(cut -f2 "$RUN_DIR/jobs.tsv" | tr '\n' ' ')" >&2
