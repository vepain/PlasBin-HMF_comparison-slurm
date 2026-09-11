#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation MOB-suite 3.1.9 (databases baked into the image)
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
mkdir -p mob-suite-build
cp "$this_script_dir/apptainer_img.def" mob-suite-build/mob-suite.def
cd mob-suite-build || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND

apptainer build mob-suite.sif mob-suite.def

#
# Finish
#
mv mob-suite.sif "$BENCH_ENVS_DIR"
cd ..
rm -rf mob-suite-build
cd "$running_dir" || exit 1
