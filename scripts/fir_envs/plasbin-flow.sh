#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
#
# Installation of PlasBin-flow (pinned commit) and its virtual environment
#
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

umask 007

PBF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-flow"
PBF_COMMIT="b34f07b04760ba2f89ecfc3f0877d0df6dd3237c"

mkdir -p "$PBF_ENVS_DIR"
cd "$PBF_ENVS_DIR" || exit 1

# ---------------------------------------------------------------------------- #
# PlasBin-flow is a set of scripts, not a package: clone it at a fixed commit
# ---------------------------------------------------------------------------- #
git clone https://github.com/cchauve/PlasBin-flow.git
git -C PlasBin-flow checkout "$PBF_COMMIT"

# ---------------------------------------------------------------------------- #
# Virtual environment (same Python and Gurobi as PlasBin-HMF)
# ---------------------------------------------------------------------------- #
module load python/3.13
module load gurobi/13.0

virtualenv --no-download venv
source venv/bin/activate
pip install --no-index --upgrade pip

pip install "gurobipy==13.0.2" --no-index
# Every non-stdlib import of PlasBin-flow's code/ (gc_content.py loads matplotlib
# even for gc_probabilities)
pip install --no-index networkx pandas numpy scipy matplotlib seaborn biopython

# ---------------------------------------------------------------------------- #
# Finish
# ---------------------------------------------------------------------------- #
deactivate
cd "$running_dir" || exit 1
