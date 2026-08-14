#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-HMF Fir environment
#
# See https://gitlab.com/vepain/plasbin-hmf for installation.
# ============================================================================ #
module load python/3.13
module load gurobi/13.0

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

pip install "gurobipy==13.0.2" --no-index

pip install "plasbin-hmf<1.0"

PBHMF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-hmf"

PBHMF_CONFIG_YAML="$PBHMF_ENVS_DIR/pbhmf_config.yaml"
GUROBI_CONFIG_YAML="$PBHMF_ENVS_DIR/gurobi_config.yaml"
