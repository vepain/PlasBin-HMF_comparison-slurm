#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation RFPlasmid 1.2 (custom .def, built from GitHub source)
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

umask 007

# ---------------------------------------------------------------------------- #
# Build the apptainer image in scratch
# ---------------------------------------------------------------------------- #
cd "/scratch/$USER" || exit 1
mkdir -p RFPlasmid-build
cp "$this_script_dir/apptainer_img.def" RFPlasmid-build/RFPlasmid.def
cd RFPlasmid-build || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND

apptainer build RFPlasmid.sif RFPlasmid.def

#
# Finish
#
mv RFPlasmid.sif "$BENCH_ENVS_DIR"
cd ..
rm -rf RFPlasmid-build
cd "$running_dir" || exit 1
