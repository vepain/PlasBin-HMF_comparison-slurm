#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-flow Fir environment
#
# The environment must be installed first, see scripts/fir_envs/plasbin-flow.sh
#
# ============================================================================ #
module load python/3.13
module load gurobi/13.0

PBF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-flow"

source "$PBF_ENVS_DIR/venv/bin/activate"

PBF_CODE_DIR="$PBF_ENVS_DIR/PlasBin-flow/code"
