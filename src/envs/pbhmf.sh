#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-HMF (pangebin) Fir environment
#
# Shared by: format-pbhmf-input, pbhmf binning, filter_bins
#
# See https://github.com/AlgoLab/pangebin for installation.
# ============================================================================ #
module load python/3.11
source "$BENCH_ENVS_DIR/env_pbhmf_py311/bin/activate"

# Cloned pangebin source tree (holds scripts/format.py used to build PBf input).
PANGEBIN_DIR="$BENCH_ENVS_DIR/pangebin"
FORMAT_PY="$PANGEBIN_DIR/scripts/format.py"
# FIXME Where is PANGEBIN_DIR?

# PB-HMF config files (examples in the pangebin repo `configs/`).
BIN_CONFIG_YAML="$BENCH_ENVS_DIR/pbhmf_configs/hmf_config.yaml"
GUROBI_CONFIG_YAML="$BENCH_ENVS_DIR/pbhmf_configs/gurobi_config.yaml"
