#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation PlasEval (Gianluca Della Vedova's fork)
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

umask 007

# ---------------------------------------------------------------------------- #
# Build the apptainer image in scratch
# ---------------------------------------------------------------------------- #
cd "/scratch/$USER" || exit 1
git clone https://github.com/gdv/PlasEval.git PlasEval-GDV
cd PlasEval-GDV || exit 1

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND
apptainer build PlasEval-GDV.sif PlasEval.def

#
# Finish
#
mv PlasEval-GDV.sif "$BENCH_ENVS_DIR"
cd ..
# Remove the git repository
rm -rf PlasEval-GDV
cd "$running_dir" || exit 1
