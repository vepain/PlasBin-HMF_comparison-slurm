#!/usr/bin/env bash
# ============================================================================ #
#
# Pipeline prelude: from the SRA runs to one filtered assembly per sample.
#
# For every sample of $SAMPLES_CSV, this single script:
#   1. downloads its short and long SRA runs (once per run, shared by samples)
#   2. submits the short-read and hybrid Unicycler assemblies as soon as the
#      runs they read are there
#   3. filters the short-read assembly (FILTER_PY) into $PRELUDE_DIR/filtered
#   4. deletes the raw short-read assembly, and each SRA run once EVERY sample
#      reading it is complete, leaving a placeholder so it is never downloaded
#      again
#
# A sample is complete once its filtered assembly and its hybrid assembly exist.
# The hybrid assembly is neither filtered nor deleted here.
#
# Run it on a login or data transfer node, NOT through sbatch, from the
# directory the assembly logs should land in (each task logs to
# ./logs/<job name>/). It loops, polling the queue, until every sample is
# complete. Everything is read back from the file tree, so killing it and
# running it again resumes where it stopped. A sample whose assembly or filter
# failed is not retried within a run: fix it (delete its `spades_assembly/`
# first) and re-run.
#
# Usage:
#   > nohup ./prelude.sh >prelude.log 2>&1 &
#
# ============================================================================ #

# ---------------------------------------------------------------------------- #
# User Variables
# ---------------------------------------------------------------------------- #
declare -r JOBS=4        # parallel downloads, more get throttled on the NCBI side
declare -r MAX_SIZE=100g # prefetch refuses runs over 20 G by default, some ONT ones are bigger
                         # (the documented unit suffixes are lowercase k/m/g/t, or u for unlimited)
declare -r POLL=300      # seconds between two passes over the samples

# ---------------------------------------------------------------------------- #
# Load base scripts
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
# shellcheck source=../config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

# The assembly scripts to submit: point them at a copy to change its SBATCH
# resources, but keep the `asm_short`/`asm_hybrid` name prefix (the queue is
# matched on it).
declare -r ASM_SHORT_SCRIPT="$BENCH_SCRIPTS_DIR/unicycler/asm_short_reads.sh"
declare -r ASM_HYBRID_SCRIPT="$BENCH_SCRIPTS_DIR/unicycler/asm_hybrid_reads.sh"
# Called as `python3 $FILTER_PY <assembly.gfa.gz> <filtered.gfa.gz>`
declare -r FILTER_PY="$BENCH_SCRIPTS_DIR/prelude/filter.py"

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

log() { echo "[$(date '+%F %T')] $*" >&2; }

# ---------------------------------------------------------------------------- #
# The samples: "<row> <sample uid> <short run> <long run>", row being the line
# of the sample in $SAMPLES_CSV, which is also its SLURM array index.
# ---------------------------------------------------------------------------- #
mapfile -t SAMPLES < <(awk -F'\t' '
    NR == 1 {
        for (i = 1; i <= NF; i++) { col[$i] = i }
        n = split("species_id sample_id short_reads long_reads", need, " ")
        for (i = 1; i <= n; i++) {
            if (!(need[i] in col)) { print "Error: no " need[i] " column in " FILENAME > "/dev/stderr"; exit 1 }
        }
        next
    }
    { print NR "\t" $col["species_id"] "-" $col["sample_id"] "\t" $col["short_reads"] "\t" $col["long_reads"] }
' "$SAMPLES_CSV")
((${#SAMPLES[@]})) || { echo "No sample in $SAMPLES_CSV" >&2; exit 1; }

is_filtered() { [[ -s "$(get_prelude_filtered_gfa_gz "$1")" || -s "$(get_unicycler_assembly_gfa_gz "$1")" ]]; }
is_hybrid_done() { [[ -s "$(get_unicycler_hybrid_assembly_dir "$1")/assembly.gfa.gz" ]]; }
# a .sra.lock means prefetch is still writing that run: a task reading it now
# would assemble a truncated read set
is_run_ready() { [[ -s "$(get_sra_dir "$1")/$1.sra" && ! -e "$(get_sra_dir "$1")/$1.sra.lock" ]]; }

# ---------------------------------------------------------------------------- #
# 1. Download
#
# Only the runs an incomplete sample still needs, and not the ones a placeholder
# says were already used up. prefetch leaves the runs it already has alone.
# ---------------------------------------------------------------------------- #
mkdir -p "$SRA_DIR"

declare -A wanted=()
for line in "${SAMPLES[@]}"; do
    IFS=$'\t' read -r _ uid sr lr <<<"$line"
    if ! is_filtered "$uid" || ! is_hybrid_done "$uid"; then
        wanted[$sr]=1
        wanted[$lr]=1
    fi
done
to_download=$(mktemp)
for run in "${!wanted[@]}"; do
    [[ -e "$(get_sra_placeholder "$run")" ]] || echo "$run"
done | sort >"$to_download"

log "$(grep -c '' "$to_download") runs to download"
# a background job is not killed by `set -e`: its status is read once it ends
xargs -a "$to_download" -P "$JOBS" -I{} \
    prefetch {} --output-directory "$SRA_DIR" --max-size "$MAX_SIZE" &
dl_pid=$!
dl_done=0
trap 'trap - TERM; kill 0' INT TERM

# ---------------------------------------------------------------------------- #
# The passes: each one reads the file tree and the queue, and acts on them
# ---------------------------------------------------------------------------- #
declare -A submitted=() # "<family>:<row>": already sent by this run, never twice
declare -A filter_failed=()
filter_warned=0
acted=0

# busy["<family>:<row>"]: tasks pending or running over the assembly trees.
# Matched on the name prefix, not on the script's own name, so that a copy with
# bigger SBATCH resources is seen too.
refresh_busy() {
    busy=()
    local out name row
    out=$(squeue -h -u "$USER" -t PENDING,RUNNING -r --Format=Name:40,ArrayTaskID) || {
        echo "squeue failed: refusing to go on without knowing what is queued." >&2
        exit 1
    }
    while read -r name row; do
        case "$name" in
        asm_short*) busy[short:$row]=1 ;;
        asm_hybrid*) busy[hybrid:$row]=1 ;;
        esac
    done <<<"$out"
}

submit() { # <family> <script> <row>...
    local family=$1 script=$2
    shift 2
    (($#)) || return 0
    if sbatch --array="$(IFS=,; echo "$*")" "$script" >&2; then
        for row in "$@"; do submitted[$family:$row]=1; done
        acted=$((acted + $#))
        log "submitted $# $family assemblies"
    else
        log "sbatch failed for the $family assemblies, retrying on the next pass"
    fi
}

submit_ready() {
    local short_rows=() hybrid_rows=() line row uid sr lr
    for line in "${SAMPLES[@]}"; do
        IFS=$'\t' read -r row uid sr lr <<<"$line"
        if ! is_filtered "$uid" && [[ ! -s "$(get_unicycler_short_assembly_dir "$uid")/assembly.gfa.gz" ]] &&
            [[ -z ${busy[short:$row]:-}${submitted[short:$row]:-} ]] && is_run_ready "$sr"; then
            short_rows+=("$row")
        fi
        if ! is_hybrid_done "$uid" && [[ -z ${busy[hybrid:$row]:-}${submitted[hybrid:$row]:-} ]] &&
            is_run_ready "$sr" && is_run_ready "$lr"; then
            hybrid_rows+=("$row")
        fi
    done
    submit short "$ASM_SHORT_SCRIPT" "${short_rows[@]}"
    submit hybrid "$ASM_HYBRID_SCRIPT" "${hybrid_rows[@]}"
}

filter_ready() {
    local line row uid raw out
    for line in "${SAMPLES[@]}"; do
        IFS=$'\t' read -r row uid _ <<<"$line"
        raw="$(get_unicycler_short_assembly_dir "$uid")/assembly.gfa.gz"
        [[ -s "$raw" && -z ${busy[short:$row]:-} && -z ${filter_failed[$uid]:-} ]] && ! is_filtered "$uid" || continue
        # never delete a raw assembly that was not filtered
        if [[ ! -f "$FILTER_PY" ]]; then
            ((filter_warned)) || log "no $FILTER_PY yet: nothing is filtered, so nothing is deleted"
            filter_warned=1
            return 0
        fi
        out=$(get_prelude_filtered_gfa_gz "$uid")
        mkdir -p "$(dirname "$out")"
        if python3 "$FILTER_PY" "$raw" "$out.tmp" && mv "$out.tmp" "$out"; then
            rm -rf "$(get_unicycler_short_assembly_dir "$uid")"
            acted=$((acted + 1))
            log "$uid filtered"
        else
            rm -f "$out.tmp"
            filter_failed[$uid]=1
            log "$uid: the filter failed, its assembly is kept"
        fi
    done
}

# A run goes when no sample still needs it: the short run is read by both
# assemblies, the long one by the hybrid only, and samples share runs, so the
# samples not done are collected first, and only what is left goes.
prune_runs() {
    local -A need=() gone=()
    local line row uid sr lr held=0 run n=0
    for line in "${SAMPLES[@]}"; do
        IFS=$'\t' read -r row uid sr lr <<<"$line"
        # a task still holding the sample may be extracting its runs right now
        [[ -n ${busy[short:$row]:-}${busy[hybrid:$row]:-} ]] && held=1 || held=0
        if ((held)) || ! is_filtered "$uid" || ! is_hybrid_done "$uid"; then need[$sr]=1; else gone[$sr]=1; fi
        if ((held)) || ! is_hybrid_done "$uid"; then need[$lr]=1; else gone[$lr]=1; fi
    done
    for run in "${!gone[@]}"; do
        [[ -z ${need[$run]:-} ]] || continue
        [[ -e "$(get_sra_placeholder "$run")" ]] && continue
        # placeholder first: a kill in between must not lead to a new download
        touch "$(get_sra_placeholder "$run")"
        rm -rf "$(get_sra_dir "$run")"
        n=$((n + 1))
    done
    ((n == 0)) || log "$n runs deleted"
    acted=$((acted + n))
}

count_complete() {
    local line uid n=0
    for line in "${SAMPLES[@]}"; do
        IFS=$'\t' read -r _ uid _ <<<"$line"
        ! is_filtered "$uid" || ! is_hybrid_done "$uid" || n=$((n + 1))
    done
    echo "$n"
}

# ---------------------------------------------------------------------------- #
# Loop until every sample is complete, or nothing can move any more
# ---------------------------------------------------------------------------- #
declare -A busy=()
while :; do
    acted=0
    refresh_busy
    submit_ready
    filter_ready
    prune_runs

    complete=$(count_complete)
    log "$complete/${#SAMPLES[@]} samples complete, ${#busy[@]} assembly tasks queued"
    ((complete == ${#SAMPLES[@]})) && break

    if ((!dl_done)) && ! kill -0 "$dl_pid" 2>/dev/null; then
        dl_done=1
        wait "$dl_pid" || log "some runs failed to download (see above): re-run prelude.sh to retry them"
    fi
    if ((dl_done && ${#busy[@]} == 0 && acted == 0)); then
        log "stuck at $complete/${#SAMPLES[@]}: nothing downloading, queued or left to do." \
            "Failed assemblies or downloads, or no $FILTER_PY."
        exit 1
    fi
    sleep "$POLL"
done

wait "$dl_pid" || true
rm -f "$to_download"
log "prelude done: filtered assemblies are in $PRELUDE_DIR/filtered"
