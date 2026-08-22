#!/usr/bin/env bash
# ============================================================================ #
#
# RFPlasmid Fir environment
#
# ============================================================================ #
module load apptainer

# TODO: CHECK rfplasmid.sif is available in BENCH_ENVS_DIR
APPTAINER_IMG="$BENCH_ENVS_DIR/rfplasmid.sif"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch,$BENCH_ROOT_DIR"
