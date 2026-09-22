#!/usr/bin/env bash
# ============================================================================ #
#
# MOB-suite Fir environment
#
# ============================================================================ #
module load apptainer

APPTAINER_IMG="$BENCH_ENVS_DIR/mob-suite.sif"
# Databases baked into the image, see scripts/fir_envs/mob-suite/apptainer_img.def
MOB_DB_DIR="/opt/mob_db"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch,$BENCH_ROOT_DIR"
