#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
#
# Installation of PlasBin-HMF
#
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

umask 007

# ---------------------------------------------------------------------------- #
# Build the compute canada wheel for plasbin-hmf
# ---------------------------------------------------------------------------- #
PBHMF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-hmf"

cd "$PBHMF_ENVS_DIR" || exit 1

module load python/3.13
module load gurobi/13.0

virtualenv --no-download venv
source venv/bin/activate
pip install --no-index --upgrade pip

pip install "gurobipy==13.0.2" --no-index
pip install "plasbin-hmf<1.0"

# ---------------------------------------------------------------------------- #
# Finish
# ---------------------------------------------------------------------------- #
deactivate
cd "$running_dir" || exit 1
