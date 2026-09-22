#!/usr/bin/env bash
#
# Usage: ./no_plasmid_hybrid_contigs.sh
#
# Lists subdirectories of the current directory where
# $dir/hybrid.gfa.csv does NOT contain "plasmid"
# in the column labeled "label".

for dir in */; do
    dir="${dir%/}"
    file="$dir/hybrid.gfa.csv"

    if [[ ! -f "$file" ]]; then
        continue # skip dirs without the file (remove this if you want them listed too)
    fi

    # Find the column index of "label" using the header row
    col_index=$(head -1 "$file" | tr ',' '\n' | grep -nx "label" | cut -d: -f1)

    if [[ -z "$col_index" ]]; then
        echo "Warning: no 'label' column in $file" >&2
        continue
    fi

    # Check if any row (excluding header) has "plasmid" in that column
    if ! tail -n +2 "$file" | awk -F',' -v col="$col_index" '$col == "plasmid" { found=1 } END { exit !found }'; then
        echo "$dir"
    fi
done
