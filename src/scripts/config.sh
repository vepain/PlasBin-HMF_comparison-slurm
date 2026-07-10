#!/usr/bin/env bash
# ============================================================================ #
#
# Configurate the benchmark
#
# ============================================================================ #
# ---------------------------------------------------------------------------- #
# Auto-configurate
# ---------------------------------------------------------------------------- #
BENCH_SCRIPT_ROOT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
#
# To let group users to modify the results
#
umask 007
#
# Source utilities
#
source "$BENCH_SCRIPT_ROOT_DIR/utils.sh"
