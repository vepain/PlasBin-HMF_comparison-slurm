#!/usr/bin/env bash
# ============================================================================ #
#
# Submit an assembly script over the samples the prelude has already downloaded.
#
# The assembly scripts extract their reads from $PRELUDE_DIR and fail on a
# sample whose runs are not there yet, so launching the whole array while
# scripts/prelude.sh is still running wastes tasks. This restricts `--array` to
# the rows that are ready, so the assemblies can start on a partial download and
# be relaunched in waves: a sample already assembled is left out of the next one.
#
# Run it on a login node, from the directory holding the script to submit.
#
# Usage:
#   > ./submit_ready.sh asm_short_reads.sh
#   > ./submit_ready.sh asm_hybrid_reads.sh
#
# ============================================================================ #

# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
declare -r PRELUDE_DIR="$BENCH_ROOT_DIR/prelude" # scripts/prelude.sh's $OUTPUT_DIR

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

set -euo pipefail

declare -r SCRIPT="${1:?usage: ./submit_ready.sh <assembly script>}"
[[ -f "$SCRIPT" ]] || {
    echo "No such script: $SCRIPT" >&2
    exit 1
}

# The hybrid script is the one reading the long_reads column: it needs both runs
# downloaded, and writes to the hybrid assembly directory.
if grep -q '"long_reads"' "$SCRIPT"; then
    read_cols="short_reads long_reads"
    asm_dir="$UNI_HYBRID_ASSEMBLY_DIR"
else
    read_cols="short_reads"
    asm_dir="$UNI_ASSEMBLY_DIR"
fi

# ---------------------------------------------------------------------------- #
# The array index is the line number of the sample in $SAMPLES_CSV
# (`sed -n "${SLURM_ARRAY_TASK_ID}p"`), so the line numbers are the array.
# ---------------------------------------------------------------------------- #
ready=$(awk -F'\t' -v d="$PRELUDE_DIR" -v a="$asm_dir" -v cols="$read_cols" '
    NR == 1 {
        for (i = 1; i <= NF; i++) { col[$i] = i }
        n = split(cols, c, " ")
        next
    }
    # Already assembled: leave it out, this is a relaunch
    system("test -s " a "/" $col["species_id"] "-" $col["sample_id"] "/assembly.gfa.gz") == 0 { next }
    {
        for (i = 1; i <= n; i++) {
            r = $col[c[i]]
            # a .sra.lock means prefetch is still writing that run: a task reading
            # it now would assemble a truncated read set
            if (system("test -s " d "/" r "/" r ".sra -a ! -e " d "/" r "/" r ".sra.lock")) { next }
        }
        print NR
    }
' "$SAMPLES_CSV")

if [[ -z "$ready" ]]; then
    echo "No sample to assemble: none is downloaded in $PRELUDE_DIR, or all are done." >&2
    exit 1
fi

echo "$(grep -c '' <<<"$ready") samples ready, out of $(($(grep -c '' "$SAMPLES_CSV") - 1))" >&2
sbatch --array="$(paste -sd, - <<<"$ready")" "$SCRIPT"
