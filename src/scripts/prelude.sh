#!/usr/bin/env bash
# ============================================================================ #
#
# Pipeline prelude: download every sample's SRA runs (short and long) at once.
#
# Standalone on purpose: it shares nothing with the benchmark scripts, so it can
# be copied anywhere and run as is. Run it on a login or data transfer node, NOT
# through sbatch: it is network bound, so one download for the whole benchmark
# beats an assembly task per sample holding a compute allocation idle while
# waiting on the NCBI side.
#
# Each run lands in `$OUTPUT_DIR/<run id>/`, which is what `fasterq-dump` takes
# to extract the FASTQ later. prefetch leaves the runs it already has alone, so
# re-run the script to retry whatever failed.
#
# Usage:
#   > ./prelude.sh
#
# ============================================================================ #

# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
declare -r SAMPLES_CSV="$BENCH_ROOT_DIR/completed_samples.csv" # tab-separated
declare -r OUTPUT_DIR="$BENCH_ROOT_DIR/prelude"
declare -r JOBS=4        # parallel downloads, more get throttled on the NCBI side
declare -r MAX_SIZE=100G # prefetch refuses runs over 20 G by default, some ONT ones are bigger

# ---------------------------------------------------------------------------- #
# Environment: only `prefetch` is needed here
# ---------------------------------------------------------------------------- #
module load sra-toolkit/3.0.9
# fail here rather than once per run if the module did not load
command -v prefetch >/dev/null || { echo "prefetch not found" >&2; exit 1; }

# ---------------------------------------------------------------------------- #
# Abort on the first failure, and let the group modify what is downloaded
# ---------------------------------------------------------------------------- #
set -euo pipefail
umask 007

# ---------------------------------------------------------------------------- #
# Download every run of the sample list
#
# Both read columns are fed to one sorted-unique list: a run shared by two
# samples is downloaded once. A run that unicycler/delete_ready.sh removed once
# its assemblies were done leaves a `<run id>.done` marker behind: it is not
# wanted again, so it is left out here. Delete the marker to download it again.
# ---------------------------------------------------------------------------- #
mkdir -p "$OUTPUT_DIR"

awk -F'\t' -v d="$OUTPUT_DIR" '
    NR == 1 {
        for (i = 1; i <= NF; i++) { col[$i] = i }
        if (!("short_reads" in col) || !("long_reads" in col)) {
            print "Error: no short_reads/long_reads column in " FILENAME > "/dev/stderr"
            exit 1
        }
        next
    }
    {
        r = $col["short_reads"]; if (system("test -e " d "/" r ".done")) { print r }
        r = $col["long_reads"];  if (system("test -e " d "/" r ".done")) { print r }
    }
' "$SAMPLES_CSV" | sort -u | xargs -P "$JOBS" -I{} \
    prefetch {} --output-directory "$OUTPUT_DIR" --max-size "$MAX_SIZE" ||
    {
        echo "Some runs failed to download (see above): re-run prelude.sh to retry them." >&2
        exit 1
    }
