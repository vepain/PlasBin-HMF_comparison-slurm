#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-HMF Fir environment
#
# See https://gitlab.com/vepain/plasbin-hmf for installation.
# ============================================================================ #
module load python/3.13
module load gurobi/13.0

PBHMF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-hmf"

source "$PBHMF_ENVS_DIR/venv/bin/activate"

PBHMF_CONFIG_YAML="$PBHMF_ENVS_DIR/pbhmf_config.yaml"
GUROBI_CONFIG_YAML="$PBHMF_ENVS_DIR/gurobi_config.yaml"
