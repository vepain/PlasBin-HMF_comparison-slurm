#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation Platon
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

umask 007

cd "/scratch/$USER" || exit 1
mkdir -p Platon-build
cp "$this_script_dir/platon/apptainer_img.def" Platon-build/Platon.def
cd Platon-build || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND

apptainer build Platon.sif Platon.def

mv Platon.sif "$BENCH_ENVS_DIR"
cd ..
rm -rf Platon-build
cd "$running_dir" || exit 1
