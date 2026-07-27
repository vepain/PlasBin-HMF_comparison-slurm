#!/usr/bin/env bash
# ============================================================================ #
#
# Python helper tools Fir environment (typer + pandas)
#
# Shared by: format-plaseval (format_binning_results.py, format_ground_truth.py)
# and merge-plaseval (merge_plaseval_evaluations.py).
# Requirements: src/scripts/tasks/*/requirements.txt (typer, pandas).
# DOCU fix the requirements file, add into zensical docs
# ============================================================================ #
module load python/3.13
source "$BENCH_ENVS_DIR/env_py_tools/bin/activate"
# FIXME The enviroment must be installed on the Fir SLURM tmp dir, not loaded.
# TODO each tool should have its own environment, not a big common one.
