#!/usr/bin/env bash
# ============================================================================ #
#
# Python helper tools Fir environment (typer + pandas)
#
# Shared by: format-plaseval (format_binning_results.py, format_ground_truth.py)
# and merge-plaseval (merge_plaseval_evaluations.py).
# Requirements: src/scripts/tasks/*/requirements.txt (typer, pandas).
# ============================================================================ #
module load python/3.13
source "$BENCH_ENVS_DIR/env_py_tools/bin/activate"
