#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation PlasEval (Gianluca Della Vedova's fork)
# ---------------------------------------------------------------------------- #
benchmark_root_dir=$1

umask 007

cd "/scratch/$USER" || exit 1
git clone https://github.com/gdv/PlasEval.git PlasEval-GDV
cd PlasEval-GDV || exit 1

# Build the apptainer image on `fir` cluster (on scratch):

module load apptainer
APPTAINER_BIND=" "
export APPTAINER_BIND
apptainer build PlasEval-GDV.sif PlasEval.def

# Test the apptainer image:

apptainer run -C PlasEval-GDV.sif --help

# Move it to the `$benchmark_root_dir/envs` directory:

mv PlasEval-GDV.sif "$benchmark_root_dir/envs"
cd ..
# Remove the git repository
rm -rf PlasEval-GDV
