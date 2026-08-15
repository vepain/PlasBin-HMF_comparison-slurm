#!/usr/bin/env bash
#
# find_tasks_to_redo.sh
#
# Usage: ./find_tasks_to_redo.sh BENCH_ROOT_DIR METHOD_CODE [OUTFILE]
#
# For each row of $SAMPLES_CSV (with header; row 1 = header), builds the
# sample_uid from the "species_id" and "sample_id" columns via
# get_sample_uid, then checks whether the corresponding uni-bin dir
# (get_uni_bin_dir SAMPLE_UID METHOD_CODE) contains either
# "no_solution.yaml" or "solution_metadata.yaml".
# If neither file exists, the row number is appended to OUTFILE
# (default: tasks_to_redo_${METHOD_CODE}.txt).

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 BENCH_ROOT_DIR METHOD_CODE [OUTFILE]" >&2
    exit 1
fi

BENCH_ROOT_DIR=$(realpath "$1")
METHOD_CODE="$2"
OUTFILE="${3:-tasks_to_redo_${METHOD_CODE}.txt}"
# ---------------------------------------------------------------------------- #
# shellcheck source=../../../src/scripts/config.sh
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

    uni_bin_dir=$(get_uni_bin_dir "$sample_uid" "$METHOD_CODE")

    if [[ -f "$uni_bin_dir/no_solution.yaml" || -f "$uni_bin_dir/solution_metadata.yaml" ]]; then
        : # done, nothing to do
    else
        echo "$row_num" >>"$OUTFILE"
        n_redo=$((n_redo + 1))
    fi
done <"$SAMPLES_CSV"

cd "$running_dir"

echo "Checked $n_total samples for method '$METHOD_CODE'."
echo "$n_redo row(s) need to be redone. Row numbers written to: $OUTFILE"
