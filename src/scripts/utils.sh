#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Benchmark utilities.
# ---------------------------------------------------------------------------- #
# Get species and sample UID
#
# Arguments:
# 1. Samples file
#
# Usage:
#   > spe_smp_id=$(get_spe_smp_id "$samples_file")
function get_spe_smp_id {
    local smp_file=$1
    local species
    species=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f1)
    local sample_id
    sample_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$smp_file" | cut -f2)

    local spe_smp_id="${species}-${sample_id}"

    echo "$spe_smp_id"
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
