#!/usr/bin/env bash
# ============================================================================ #
#
# PlasBin-HMF Fir environment
#
# See https://gitlab.com/vepain/plasbin-hmf for installation.
#
# Warning
# -------
# You first need to build a custom gurobipy wheel, see benchmark documentation.
# ============================================================================ #
module load python/3.13
module load gurobi/13.0

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

#
# Install gurobipy: https://docs.alliancecan.ca/wiki/Gurobi
#
cd "$SLURM_TMPDIR" || exit
python -m pip install "$BENCH_ENVS_DIR/gurobipy-13.0.2+computecanada-cp313-cp313-linux_x86_64.whl"

pip install plasbin-hmf

PBHMF_ENVS_DIR="$BENCH_ENVS_DIR/plasbin-hmf"

PBHMF_CONFIG_YAML="$PBHMF_ENVS_DIR/pbhmf_config.yaml"
GUROBI_CONFIG_YAML="$PBHMF_ENVS_DIR/gurobi_config.yaml"
