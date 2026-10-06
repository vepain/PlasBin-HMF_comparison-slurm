#!/usr/bin/env bash
# ============================================================================ #
#
# Format binning inputs environment
#
# ============================================================================ #
module load apptainer

APPTAINER_IMG="$BENCH_ENVS_DIR/format-binning-inputs.sif"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch,$BENCH_ROOT_DIR"
