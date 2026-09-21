#!/usr/bin/env bash
# ============================================================================ #
#
# Submit an assembly script over the samples the prelude has already downloaded.
#
# The assembly scripts extract their reads from $SRA_DIR and fail on a sample
# whose runs are not there yet, so launching the whole array while
# prelude.sh is still running wastes tasks. This restricts `--array` to
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
# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
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
    family="asm_hybrid"
else
    read_cols="short_reads"
    asm_dir="$UNI_SHORT_ASSEMBLY_DIR"
    family="asm_short"
fi

# Tasks already pending or running over the same assembly tree. A sample
# submitted twice has two Unicyclers sharing one output directory, and the SPAdes
# runs crash each other over their K*/ working files -- the assembled sample is
# not there yet to exclude them, so the queue has to.
#
# Matched on the `asm_short`/`asm_hybrid` name prefix, not on this script's own
# name: a copy with bigger SBATCH resources writes the same tree, and must be
# seen. Keep the prefix when making such a copy.
queued=$(squeue -h -u "$USER" -t PENDING,RUNNING -r --Format=Name:40,ArrayTaskID |
    awk -v f="$family" '$1 ~ "^" f { print $2 }' | paste -sd, -) || {
    echo "squeue failed: refusing to submit without knowing what is already queued." >&2
    exit 1
}

# ---------------------------------------------------------------------------- #
# The array index is the line number of the sample in $SAMPLES_CSV
# (`sed -n "${SLURM_ARRAY_TASK_ID}p"`), so the line numbers are the array.
# ---------------------------------------------------------------------------- #
ready=$(awk -F'\t' -v d="$SRA_DIR" -v a="$asm_dir" -v cols="$read_cols" -v queued="$queued" '
    BEGIN { n_q = split(queued, q, ","); for (i = 1; i <= n_q; i++) { skip[q[i]] = 1 } }
    NR == 1 {
        for (i = 1; i <= NF; i++) { col[$i] = i }
        n = split(cols, c, " ")
        next
    }
    # Already queued or running: leave it to the job that has it
    NR in skip { next }
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
    echo "No sample to assemble: none is downloaded in $SRA_DIR, or all are done." >&2
    exit 1
fi

echo "$(grep -c '' <<<"$ready") samples ready, out of $(($(grep -c '' "$SAMPLES_CSV") - 1))" >&2
[[ -z "$queued" ]] || echo "(skipped $(tr ',' '\n' <<<"$queued" | grep -c '') already queued)" >&2
sbatch --array="$(paste -sd, - <<<"$ready")" "$SCRIPT"
