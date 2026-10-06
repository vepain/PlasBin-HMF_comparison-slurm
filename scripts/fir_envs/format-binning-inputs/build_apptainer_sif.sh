#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Build the apptainer image: pangebin + format.py as the entrypoint
# ---------------------------------------------------------------------------- #
set -eo pipefail

BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

umask 007

# Run from this directory so that `%files format.py` in the .def is found
cd "$(dirname "${BASH_SOURCE[0]}")"

module load apptainer

# Keep temporary build data on scratch, and don't bind anything during the build
export APPTAINER_TMPDIR="/scratch/$USER"
export APPTAINER_BIND=" "

apptainer build --force "$BENCH_ENVS_DIR/format-binning-inputs.sif" apptainer_img.def
