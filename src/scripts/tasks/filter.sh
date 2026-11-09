filter_ready() {
    local line row uid raw out
    for line in "${SAMPLES[@]}"; do
        IFS=$'\t' read -r row uid _ <<<"$line"
        raw="$(get_prelude_unicycler_short_assembly_dir "$uid")/assembly.gfa.gz"
        [[ -s "$raw" && -z ${busy[short:$row]:-} && -z ${filter_failed[$uid]:-} ]] && ! is_hybrid_done "$uid" || continue
        # never delete a raw assembly that was not filtered
        if [[ ! -f "$BENCH_SCRIPTS_DIR/prelude/filter.py" ]]; then
            ((filter_warned)) || log "no $BENCH_SCRIPTS_DIR/prelude/filter.py yet: nothing is filtered, so nothing is deleted"
            filter_warned=1
            return 0
        fi
        out=$(get_prelude_filtered_gfa_gz "$uid")
        mkdir -p "$(dirname "$out")"
        if python3 "$BENCH_SCRIPTS_DIR/prelude/filter.py" "$raw" "$out.tmp" && mv "$out.tmp" "$out"; then
            rm -rf "$(get_prelude_unicycler_short_assembly_dir "$uid")"
            acted=$((acted + 1))
            log "$uid filtered"
        else
            rm -f "$out.tmp"
            filter_failed[$uid]=1
            log "$uid: the filter failed, its assembly is kept"
        fi
    done
}