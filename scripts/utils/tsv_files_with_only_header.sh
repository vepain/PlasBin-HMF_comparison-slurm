#!/bin/bash
# ---------------------------------------------------------------------------- #
# List files with only header.
#
# Usage:
#   > tsv_files_with_only_header.sh "<pattern>"
#
# Example:
#   > tsv_files_with_only_header.sh "/path can have spaces/to/*.tsv"
# ---------------------------------------------------------------------------- #
pattern="$1"

while IFS= read -r f; do
    if [ "$(wc -l <"$f" | tr -d ' ')" -eq 1 ]; then
        echo "$f"
    fi
done < <(compgen -G "$pattern")
