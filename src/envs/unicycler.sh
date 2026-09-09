#!/usr/bin/env bash
# ============================================================================ #
#
# Unicycler Fir environment
#
# ============================================================================ #
# SRA toolkit provides `prefetch` and `fastq-dump` directly (no container)
module load sra-toolkit/3.0.9

module load apptainer

APPTAINER_IMG="$BENCH_ENVS_DIR/unicycler.sif"
# See https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts
export APPTAINER_BINDPATH="/project,/scratch,$BENCH_ROOT_DIR"
