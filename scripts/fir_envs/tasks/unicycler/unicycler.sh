#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation PlasEval (Gianluca Della Vedova's fork)
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$1
# shellcheck source=../../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

umask 007

running_dir=$(pwd)

this_parent_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
unicycler_apptainer_def="$this_parent_dir/unicycler.def"

# ---------------------------------------------------------------------------- #
# Building apptainer image in scratch
# ---------------------------------------------------------------------------- #
cd "/scratch/$USER" || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND
apptainer build unicycler.sif "$unicycler_apptainer_def"

#
# Finish
#
mv unicycler.sif "$BENCH_ENVS_DIR"
cd "$running_dir" || exit 1
