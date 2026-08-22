#!/usr/bin/env bash
# ============================================================================ #
#
# PlasEval (Gianluca Della Vedova's fork) Fir environment
#
# ============================================================================ #
module load apptainer

APPTAINER_IMG="$BENCH_ENVS_DIR/PlasEval-GDV.sif"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch,$BENCH_ROOT_DIR"
