#!/usr/bin/env bash
# ============================================================================ #
#
# Delete the SRA runs whose assemblies are done.
#
# PAUSED: the assemblies it reads are about to feed the filter step, which is
# what really decides when a run can go. It still runs, but do not wire it into
# a pipeline until that step exists.
#
# A run goes only once every assembly reading it exists:
#   - the long run  is read by the hybrid assembly only
#   - the short run is read by BOTH the short-read and the hybrid assembly
# which is why this is a pass of its own, and not an `rm` at the end of
# asm_short_reads.sh: that task cannot know whether the hybrid one has run.
#
# --only-short says no hybrid assembly is coming: a sample's short run then only
# waits for its short-read assembly, and the long runs are dropped right away --
# nothing is left to read them.
#
# Run it on a login node, as often as you like while the assemblies progress.
#
# Usage:
#   > ./delete_ready.sh [--only-short]
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

only_short=0
case "${1:-}" in
"") ;;
--only-short) only_short=1 ;;
*)
    echo "usage: $0 [--only-short]" >&2
    exit 1
    ;;
esac

# A task still holding a sample keeps its runs, whatever the assemblies look
# like: it may be extracting them right now. Any assembly job counts, matched on
# the `asm_short`/`asm_hybrid` name prefix so that copies with bigger SBATCH
# resources are seen too -- keep the prefix when making one.
queued=$(squeue -h -u "$USER" -t PENDING,RUNNING -r --Format=Name:40,ArrayTaskID |
    awk '$1 ~ /^asm_(short|hybrid)/ { print $2 }' | paste -sd, -) || {
    echo "squeue failed: refusing to delete without knowing what is running." >&2
    exit 1
}

# ---------------------------------------------------------------------------- #
# A run is deletable when no row still needs it: rows share runs, so the rows
# that are not done yet are collected first, and only what is left goes.
# ---------------------------------------------------------------------------- #
runs=$(awk -F'\t' -v s="$UNI_SHORT_ASSEMBLY_DIR" -v h="$UNI_HYBRID_ASSEMBLY_DIR" -v queued="$queued" \
    -v only_short="$only_short" '
    BEGIN { n_q = split(queued, q, ","); for (i = 1; i <= n_q; i++) { busy[q[i]] = 1 } }
    NR == 1 { for (i = 1; i <= NF; i++) { col[$i] = i }; next }
    {
        uid = $col["species_id"] "-" $col["sample_id"]
        short_done  = (system("test -s " s "/" uid "/assembly.gfa.gz") == 0)
        # --only-short: no hybrid assembly is coming, so nothing waits on one
        hybrid_done = only_short ? 1 : (system("test -s " h "/" uid "/assembly.gfa.gz") == 0)
        held = (NR in busy)

        sr = $col["short_reads"]
        lr = $col["long_reads"]
        # the short run is read by both assemblies, the long one by the hybrid only
        if (held || !short_done || !hybrid_done) { need[sr] = 1 } else { gone[sr] = 1 }
        if (held || !hybrid_done)                { need[lr] = 1 } else { gone[lr] = 1 }
    }
    END { for (r in gone) { if (!(r in need)) { print r } } }
' "$SAMPLES_CSV")

if [[ -z "$runs" ]]; then
    echo "No run to delete: every downloaded run is still needed by an assembly." >&2
    exit 0
fi

# ---------------------------------------------------------------------------- #
# Delete, and leave the marker prelude.sh reads
# ---------------------------------------------------------------------------- #
n=0
m=0
while read -r run; do
    sra_dir=$(get_sra_dir "$run")
    if [[ -d "$sra_dir" ]]; then
        rm -rf "${sra_dir:?}"
        n=$((n + 1))
    fi
    m=$((m + 1))
done <<<"$runs"

# Nothing records that a run is gone any more: a later prelude.sh downloads it
# again. That was the marker's job, and it waits for the filter step.

echo "$m runs no longer needed: $n deleted from $SRA_DIR, $((m - n)) never downloaded" >&2
if ((only_short)); then
    echo "(--only-short: the long runs went with them)" >&2
fi
