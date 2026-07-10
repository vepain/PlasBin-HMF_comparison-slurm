#!/usr/bin/env bash
# ============================================================================ #
#
# PlasEval (Gianluca Della Vedova's fork) Fir environment
#
# ============================================================================ #
module load apptainer
APPTAINER_IMG="$BENCH_ENVS_DIR/PlasEval-GDV.sif"
APPTAINER_BINDS=(
    -B
    "/project"
    -B
    "/scratch"
)
