#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Initialize the benchmark environment
#
# Usage
# ./init.sh $BENCHMARK_ROOT_DIR
# ---------------------------------------------------------------------------- #

if [ "$#" -ne 1 ]; then
    echo "Usage: ./init.sh \$BENCHMARK_ROOT_DIR"
    exit 1
fi

bench_root_dir=$1

umask 007

cp -R src/* "$bench_root_dir"

# ---------------------------------------------------------------------------- #
# In every shell script, replace the TODO:BENCH_ROOT_DIR token
# ---------------------------------------------------------------------------- #
find "$bench_root_dir" -type f -name '*.sh' -exec \
    sed -i "s|TODO:BENCH_ROOT_DIR|$bench_root_dir|g" {} +

# ---------------------------------------------------------------------------- #
# Make all scripts executable
# ---------------------------------------------------------------------------- #
find "$bench_root_dir" -type f -name '*.sh' -exec \
    chmod +x {} +
