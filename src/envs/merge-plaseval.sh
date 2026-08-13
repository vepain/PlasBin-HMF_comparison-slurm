#!/usr/bin/env bash
# ============================================================================ #
#
# Merge Plaseval outputs
#
# ============================================================================ #
module load python/3.13
module load gurobi/13.0

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

pip install "typer>=0.21,<1.0"
pip install "pandas<4.0"
