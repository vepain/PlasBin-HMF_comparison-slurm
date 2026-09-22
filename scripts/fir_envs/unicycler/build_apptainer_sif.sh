#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation Unicycler 0.5.1
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

umask 007

# ---------------------------------------------------------------------------- #
# Build the apptainer image in scratch
# ---------------------------------------------------------------------------- #
cd "/scratch/$USER" || exit 1
mkdir -p unicycler-build
cp "$this_script_dir/apptainer_img.def" unicycler-build/unicycler.def
cd unicycler-build || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND

apptainer build unicycler.sif unicycler.def

#
# Finish
#
mv unicycler.sif "$BENCH_ENVS_DIR"
cd ..
rm -rf unicycler-build
cd "$running_dir" || exit 1
