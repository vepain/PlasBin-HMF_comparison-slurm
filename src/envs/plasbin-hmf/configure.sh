#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-HMF Fir environment
#
# See https://gitlab.com/vepain/plasbin-hmf for installation.
# ============================================================================ #
module load StdEnv/2023 gcc/12.3
module load python/3.13
module load gurobi

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip
pip install plasbin-hmf

PBHMF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-hmf"

PBHMF_CONFIG_YAML="$PBHMF_ENVS_DIR/pbhmf_config.yaml"
GUROBI_CONFIG_YAML="$PBHMF_ENVS_DIR/gurobi_config.yaml"
