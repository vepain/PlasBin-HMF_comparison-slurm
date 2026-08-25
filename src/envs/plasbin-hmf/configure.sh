#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-HMF Fir environment
#
# You must create the virtual environment first.
# See https://gitlab.com/vepain/plasbin-hmf for installation.
#
# ============================================================================ #
module load python/3.13
module load gurobi/13.0

PBHMF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-hmf"

source "$PBHMF_ENVS_DIR/venv/bin/activate"

PBHMF_CONFIG_YAML="$PBHMF_ENVS_DIR/pbhmf_config.yaml"
PBHMF_CONFIG_ST_CONST_YAML="$PBHMF_ENVS_DIR/pbhmf_config_st-const.yaml"
PBHMF_CONFIG_MAXCOVRATIO_20_YAML="$PBHMF_ENVS_DIR/pbhmf_config_mcr20.yaml"

GUROBI_CONFIG_YAML="$PBHMF_ENVS_DIR/gurobi_config.yaml"
