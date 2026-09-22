#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation gplasCC (gplas + plasmidCC, conda env in a micromamba image)
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
mkdir -p gplascc-build
# the .def's %files section needs the conda env and the pip requirements next to it
cp "$this_script_dir/apptainer_img.def" \
    "$this_script_dir/conda_env.yaml" \
    "$this_script_dir/requirements.txt" \
    gplascc-build/
cd gplascc-build || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND

apptainer build gplascc.sif apptainer_img.def

#
# Finish
#
mv gplascc.sif "$BENCH_ENVS_DIR"
cd ..
rm -rf gplascc-build
cd "$running_dir" || exit 1
