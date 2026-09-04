#!/usr/bin/env bash
# ============================================================================ #
#
# Platon Fir environment
#
# ============================================================================ #
module load apptainer

APPTAINER_IMG="$BENCH_ENVS_DIR/Platon.sif"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch,$BENCH_ROOT_DIR"
