#!/usr/bin/env bash
# ============================================================================ #
#
# Configurate the benchmark
#
# ============================================================================ #
BENCH_ROOT_DIR=$1
# ---------------------------------------------------------------------------- #
# Auto-configurate
# ---------------------------------------------------------------------------- #
BENCH_SCRIPTS_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
#
# To let group users to modify the results
#
umask 007
#
# Load file tree layout variables
#
source "$BENCH_SCRIPTS_DIR/filetree_layout.sh" "$BENCH_ROOT_DIR"
#
# Source utilities
#
source "$BENCH_SCRIPTS_DIR/utils.sh" "$BENCH_ROOT_DIR"
