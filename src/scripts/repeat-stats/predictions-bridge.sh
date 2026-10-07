#!/bin/bash
# ---------------------------------------------------------------------------- #
# SLURM script (single job, no array) - get methods (predictions) repeat stats
# Handles two storage logics:
#   - METHOD_CODES        : methods respecting the new storage logic
#   - BRIDGE_METHOD_CODES : methods still using the old storage logic (bridge)
# ---------------------------------------------------------------------------- #
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=3:00:00
#SBATCH --output=logs/%x/%j.out
#SBATCH --error=logs/%x/%j.err
# ============================================================================ #
#                                USER VARIABLES                                #
# ============================================================================ #
# Methods respecting the new storage logic
METHOD_CODES=(
    "pbhmf_rfpl"
    "pbhmf_rfpl_filt"
    "pbhmf_rfpl_recomb26"
    "pbhmf_rfpl_recomb26_filt"
    "pbhmf_rfpl_mcr10"
    "pbhmf_rfpl_mcr10_filt"
    "pbhmf_rfpl_mcr10_st-const"
    "pbhmf_rfpl_mcr10_st-const_filt"
)

# Methods using the old storage logic (reached through the bridge)
BRIDGE_METHOD_CODES=(
    "mob"
    "gpcc_rfpl"
    "pbf_rfpl"
    "pbf_rfpl_filt"
)
# ---------------------------------------------------------------------------- #
#                               Verify Arguments                               #
# ---------------------------------------------------------------------------- #
if [[ ${#METHOD_CODES[@]} -eq 0 && ${#BRIDGE_METHOD_CODES[@]} -eq 0 ]]; then
    echo "ERROR: METHOD_CODES and BRIDGE_METHOD_CODES are both empty" >&2
    exit 1
fi

# Build the ordered list of all methods + where each one is stored
ALL_METHODS=()
declare -A METHOD_SOURCE # method_code -> "new" | "bridge"

for method_code in "${METHOD_CODES[@]}"; do
    ALL_METHODS+=("$method_code")
    METHOD_SOURCE["$method_code"]="new"
done

for method_code in "${BRIDGE_METHOD_CODES[@]}"; do
    if [[ -n "${METHOD_SOURCE[$method_code]:-}" ]]; then
        echo "ERROR: method '$method_code' is in both METHOD_CODES and BRIDGE_METHOD_CODES" >&2
        exit 1
    fi
    ALL_METHODS+=("$method_code")
    METHOD_SOURCE["$method_code"]="bridge"
done

# ============================================================================ #
#                                  ENVIRONMENT                                 #
# ============================================================================ #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
#                               Tool Environment                               #
# ---------------------------------------------------------------------------- #
# shellcheck source=../../envs/repeat-stats.sh
source "$BENCH_ENVS_DIR/repeat-stats.sh"

# ---------------------------------------------------------------------------- #
#                      Bridge (Old Data Storage Logic)                         #
# ---------------------------------------------------------------------------- #
old_data_dir="/project/def-chauvec/wg-anoph/benchmarking/DATA"
bin_res_dir="$old_data_dir/RESULTS/FORMATTED_BINS/UNICYCLER/BINNING_RESULTS"

# Usage:
#   pred_tsv=$(get_bridge_pred_plaseval_fmt "$smp_uid" "$method_code")
function get_bridge_pred_plaseval_fmt() {
    local _smp_uid=$1     # Sample UID
    local _method_code=$2 # Method code
    echo "$bin_res_dir/$_smp_uid.$_method_code.tsv"
}

# Resolve the predictions TSV of a (sample, method) pair, depending on the source
# Usage:
#   pred_tsv=$(get_method_pred_tsv "$smp_uid" "$method_code")
function get_method_pred_tsv() {
    local _smp_uid=$1     # Sample UID
    local _method_code=$2 # Method code
    if [[ "${METHOD_SOURCE[$_method_code]}" == "bridge" ]]; then
        get_bridge_pred_plaseval_fmt "$_smp_uid" "$_method_code"
    else
        get_pred_plaseval_fmt "$_smp_uid" "$_method_code"
    fi
}

# ============================================================================ #
#                                    OUTPUTS                                   #
# ============================================================================ #
repeat_stats_tsv="$UNI_REPEAT_STATS_PREDS_TSV"
mkdir -p "$(dirname "$repeat_stats_tsv")"

py_script="$BENCH_SCRIPTS_DIR/repeat-stats/repeat_stats.py"

# Get species_id/sample_id tuples via utils.sh
mapfile -t sample_tuples < <(get_sample_tuples "$ONLY_LABELLED_SAMPLES_TSV")

# ============================================================================ #
#                                      RUN                                     #
# ============================================================================ #
# ---------------------------------------------------------------------------- #
#                     Compute Repeat Stats For Each Method                     #
# ---------------------------------------------------------------------------- #
per_method_dir="$SLURM_TMPDIR/per_method"
mkdir -p "$per_method_dir"

for method_code in "${ALL_METHODS[@]}"; do
    echo "[INFO] Processing method: $method_code (${METHOD_SOURCE[$method_code]} storage)"

    # Input TSV of the python script (sample_uid, species_id, bins_tsv)
    tmp_tsv="$per_method_dir/$method_code.input.tsv"
    printf "sample_uid\tspecies_id\tbins_tsv\n" >"$tmp_tsv"

    for tuple in "${sample_tuples[@]}"; do
        IFS=$'\t' read -r species_id sample_id <<<"$tuple"
        smp_uid=$(get_sample_uid "$species_id" "$sample_id")
        pred_tsv=$(get_method_pred_tsv "$smp_uid" "$method_code")

        if [[ ! -f "$pred_tsv" ]]; then
            echo "[WARN] Missing file for method=$method_code sample=$smp_uid: $pred_tsv" >&2
            continue
        fi
        printf "%s\t%s\t%s\n" "$smp_uid" "$species_id" "$pred_tsv" >>"$tmp_tsv"
    done

    python3 "$py_script" "$tmp_tsv" "$per_method_dir/$method_code.stats.tsv"
done

# ---------------------------------------------------------------------------- #
#                 Merging (insert Method_code After Species_id)                #
# ---------------------------------------------------------------------------- #
# Header: sample_uid  species_id  method_code  num_contigs  ...
first_method="${ALL_METHODS[0]}"
head -n 1 "$per_method_dir/$first_method.stats.tsv" |
    awk 'BEGIN { FS = OFS = "\t" } { $2 = $2 OFS "method_code"; print }' \
        >"$repeat_stats_tsv"

# Body: append every method's rows (header skipped), with the method code inserted
for method_code in "${ALL_METHODS[@]}"; do
    tail -n +2 "$per_method_dir/$method_code.stats.tsv" |
        awk -v m="$method_code" 'BEGIN { FS = OFS = "\t" } { $2 = $2 OFS m; print }' \
            >>"$repeat_stats_tsv"
done

echo "[INFO] Merged repeat stats written to: $repeat_stats_tsv"
