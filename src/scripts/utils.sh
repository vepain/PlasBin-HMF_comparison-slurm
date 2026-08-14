#!/usr/bin/env bash
# ============================================================================ #
#
# Benchmark utilities.
#
# ============================================================================ #

# ============================================================================ #
#                                  SAMPLES TSV                                 #
# ============================================================================ #
# get_tsv_col_idx <tsv_file> <col_name>
# Prints the 1-based column index of col_name in the TSV header.
# Exits with error if not found.
get_tsv_col_idx() {
    local tsv_file="$1"
    local col_name="$2"
    local idx

    idx=$(awk -F'\t' -v col="$col_name" '
        NR==1 {
            for (i=1; i<=NF; i++) if ($i==col) { print i; exit }
        }
    ' "$tsv_file")

    if [[ -z "$idx" ]]; then
        echo "Error: column '$col_name' not found in $tsv_file" >&2
        return 1
    fi

    echo "$idx"
}

# get_tsv_col_values <tsv_file> <col_name>
# Prints all values (one per line) of the given column, skipping the header.
get_tsv_col_values() {
    local tsv_file="$1"
    local col_name="$2"
    local idx

    idx=$(get_tsv_col_idx "$tsv_file" "$col_name") || return 1

    awk -F'\t' -v c="$idx" 'NR>1 {print $c}' "$tsv_file"
}

# get_sample_uid <species_id> <sample_id>
# Builds a sample UID from species_id and sample_id.
# Centralizing this ensures the format stays consistent everywhere.
get_sample_uid() {
    local species_id="$1"
    local sample_id="$2"
    echo "${species_id}-${sample_id}"
}

# get_sample_tuples <samples_tsv>
# Prints "species_id\tsample_id" pairs, one per line, skipping the header.
get_sample_tuples() {
    local samples_tsv="$1"
    local species_idx sample_idx

    species_idx=$(get_tsv_col_idx "$samples_tsv" "species_id") || return 1
    sample_idx=$(get_tsv_col_idx "$samples_tsv" "sample_id") || return 1

    awk -F'\t' -v sp="$species_idx" -v sm="$sample_idx" '
        NR>1 { print $sp "\t" $sm }
    ' "$samples_tsv"
}

# get_sample_uids <samples_tsv>
# Prints sample UIDs built as "${species_id}-${sample_id}", one per line,
# by merging the species_id and sample_id columns.
get_sample_uids() {
    local samples_tsv="$1"
    local species_idx sample_idx

    species_idx=$(get_tsv_col_idx "$samples_tsv" "species_id") || return 1
    sample_idx=$(get_tsv_col_idx "$samples_tsv" "sample_id") || return 1

    awk -F'\t' -v sp="$species_idx" -v sm="$sample_idx" '
        NR>1 { print $sp "-" $sm }
    ' "$samples_tsv"
}

# ============================================================================ #
#                                    SBATCH                                    #
# ============================================================================ #
# Get species and sample UID
#
# Arguments:
# 1. Samples file
#
# Usage:
#   > spe_smp_id=$(get_sample_uid_from_slurm_array "$samples_file")
function get_sample_uid_from_slurm_array {
    local samples_tsv=$1

    local species_idx species_id
    species_idx=$(get_tsv_col_idx "$samples_tsv" "species_id") || return 1
    species_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$samples_tsv" | cut -f"$species_idx")

    local sample_idx sample_id
    sample_idx=$(get_tsv_col_idx "$samples_tsv" "sample_id") || return 1
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$samples_tsv" | cut -f"$sample_idx")

    get_sample_uid "$species_id" "$sample_id"
}

# Usage:
#   > register_job_id "$output_dir"
#
# output_dir must be the parent directory of all sample results
# (either they are files or they are structured by directories)
function register_job_id() {
    local output_dir=$1
    mkdir -p "$output_dir" 2>/dev/null
    touch "$output_dir/job_id_$SLURM_ARRAY_JOB_ID"
}
