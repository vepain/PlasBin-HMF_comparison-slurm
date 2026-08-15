#!/usr/bin/env bash
#
# tasks_to_redo_deval.sh
#
# Usage: ./tasks_to_redo_comp.sh METHOD_CODE [OUTFILE]
#
# For each sample in the sample file, check if plaseval (eval command)
# has produced any log or out files.
# If neither file exists, the row number is appended to OUTFILE
# (default: tasks_to_redo_${METHOD_CODE}.txt).

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 METHOD_CODE [OUTFILE]" >&2
    exit 1
fi

METHOD_CODE="$1"
OUTFILE="${2:-tasks_to_redo_${METHOD_CODE}.txt}"
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

umask 007

# ---------------------------------------------------------------------------- #

if [[ ! -f "$SAMPLES_CSV" ]]; then
    echo "Error: SAMPLES_CSV not found: $SAMPLES_CSV" >&2
    exit 1
fi

species_col_idx=$(get_tsv_col_idx "$SAMPLES_CSV" "species_id")
sample_col_idx=$(get_tsv_col_idx "$SAMPLES_CSV" "sample_id")

if [[ -z "$species_col_idx" || -z "$sample_col_idx" ]]; then
    echo "Error: could not find 'species_id' and/or 'sample_id' columns in $SAMPLES_CSV" >&2
    exit 1
fi

n_redo=0
n_total=0
row_num=0

eval_dir=$(get_plaseval_eval_meth_dir "$METHOD_CODE")

rm -f "$OUTFILE"

while IFS=$'\t' read -r -a fields; do
    row_num=$((row_num + 1))

    # Skip the header row itself
    if [[ "$row_num" -eq 1 ]]; then
        continue
    fi

    species_id="${fields[$((species_col_idx - 1))]}"
    sample_id="${fields[$((sample_col_idx - 1))]}"

    if [[ -z "$species_id" || -z "$sample_id" ]]; then
        echo "Warning: empty species_id/sample_id at row $row_num, skipping" >&2
        continue
    fi

    sample_uid=$(get_sample_uid "$species_id" "$sample_id")
    n_total=$((n_total + 1))

    plaseval_out=$(get_plaseval_eval_out "$eval_dir" "$sample_uid")
    plaseval_log=$(get_plaseval_eval_log "$eval_dir" "$sample_uid")

    if [[ -f "$plaseval_out" || -f "$plaseval_log" ]]; then
        : # done, nothing to do
    else
        echo "$row_num" >>"$OUTFILE"
        n_redo=$((n_redo + 1))
    fi
done <"$SAMPLES_CSV"

cd "$running_dir"

echo "Checked $n_total samples for method '$METHOD_CODE'."
echo "$n_redo row(s) need to be redone. Row numbers written to: $OUTFILE"
