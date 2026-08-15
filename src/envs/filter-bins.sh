#!/usr/bin/env bash
# ============================================================================ #
#
# Filter bins (in PlasBin-flow format)
#
# ============================================================================ #
module load python/3.13

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

pip install --no-index "typer>=0.21,<1.0"
pip install --no-index "pandas<4.0"
