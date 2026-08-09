#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Environment script for Fir HPC
# ---------------------------------------------------------------------------- #

envs_dir="/project/6001426/wg-anoph/benchmarking/2026_Plasmid_Binning_Bench/hyplas_samples/envs"

# ---------------------------------------------------------------------------- #
# SRA toolkit
# ---------------------------------------------------------------------------- #
module load sra-toolkit/3.0.9

# ---------------------------------------------------------------------------- #
# Unicycler
# ---------------------------------------------------------------------------- #
module load apptainer/1.4.5

unicycler_apptainer_img="$envs_dir/apptainer/unicycler.sif"

UNICYCLER_CMD_PREFIX=(
    apptainer run
    -C
    -B /project
    -B /scratch
    -W "$SLURM_TMPDIR"
    "$unicycler_apptainer_img"
)
