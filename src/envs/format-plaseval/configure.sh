#!/usr/bin/env bash
# ============================================================================ #
#
# Format binning results for PlasEval Fir environment
#
# ============================================================================ #
module load python/3.13

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

PLASEVAL_FMT_ENVS_DIR="$BENCH_ENVS_DIR/format-plaseval"

pip install --no-index -r "$PLASEVAL_FMT_ENVS_DIR/requirements.txt"
