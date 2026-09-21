#!/usr/bin/env bash
# ============================================================================ #
#
# Pipeline prelude: download every sample's SRA runs (short and long) at once.
#
# Run it on a login or data transfer node, NOT through sbatch: it is network
# bound, so one download for the whole benchmark beats an assembly task per
# sample holding a compute allocation idle while waiting on the NCBI side.
#
# Each run lands in `get_sra_dir`, which is what `fasterq-dump` takes to extract
# the FASTQ later. prefetch leaves the runs it already has alone, so re-run the
# script to retry whatever failed.
#
# Usage:
#   > ./prelude.sh
#
# ============================================================================ #

# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r JOBS=4        # parallel downloads, more get throttled on the NCBI side
declare -r MAX_SIZE=100g # prefetch refuses runs over 20 G by default, some ONT ones are bigger
                         # (the documented unit suffixes are lowercase k/m/g/t, or u for unlimited)

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# ---------------------------------------------------------------------------- #
# Environment: only `prefetch` is needed here
# ---------------------------------------------------------------------------- #
module load sra-toolkit/3.0.9
# fail here rather than once per run if the module did not load
command -v prefetch >/dev/null || { echo "prefetch not found" >&2; exit 1; }

# ---------------------------------------------------------------------------- #
# Abort on the first failure (config.sh already set the group-writable umask)
# ---------------------------------------------------------------------------- #
set -euo pipefail

# ---------------------------------------------------------------------------- #
# Download every run of the sample list
#
# Both read columns are fed to one sorted-unique list: a run shared by two
# samples is downloaded once.
# ---------------------------------------------------------------------------- #
mkdir -p "$SRA_DIR"

awk -F'\t' '
    NR == 1 {
        for (i = 1; i <= NF; i++) { col[$i] = i }
        if (!("short_reads" in col) || !("long_reads" in col)) {
            print "Error: no short_reads/long_reads column in " FILENAME > "/dev/stderr"
            exit 1
        }
        next
    }
    { print $col["short_reads"]; print $col["long_reads"] }
' "$SAMPLES_CSV" | sort -u | xargs -P "$JOBS" -I{} \
    prefetch {} --output-directory "$SRA_DIR" --max-size "$MAX_SIZE" ||
    {
        echo "Some runs failed to download (see above): re-run prelude.sh to retry them." >&2
        exit 1
    }
