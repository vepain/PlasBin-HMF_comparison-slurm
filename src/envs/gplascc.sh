#!/usr/bin/env bash
# ============================================================================ #
#
# GPLAScc Fir environment
#
# ============================================================================ #
module load apptainer

APPTAINER_IMG="$BENCH_ENVS_DIR/gplascc.sif"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch"
