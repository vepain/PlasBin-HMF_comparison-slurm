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

mkdir -p "$bench_root_dir"
bench_root_dir=$(realpath "$bench_root_dir") # must create the directory before knowing its absolute path
cp -R src/* "$bench_root_dir"

echo "Instantiated benchmark in $bench_root_dir"

# ---------------------------------------------------------------------------- #
# In every shell script, replace the TODO:BENCH_ROOT_DIR token
# ---------------------------------------------------------------------------- #
find "$bench_root_dir/envs" "$bench_root_dir/scripts" -type f -name '*.sh' -exec \
    sed -i "s|TODO:BENCH_ROOT_DIR|$bench_root_dir|g" {} +

# ---------------------------------------------------------------------------- #
# Make all scripts executable
# ---------------------------------------------------------------------------- #
find "$bench_root_dir/envs" "$bench_root_dir/scripts" -type f -name '*.sh' -exec \
    chmod +x {} +

# ---------------------------------------------------------------------------- #
#                            Create A Data Directory                           #
# ---------------------------------------------------------------------------- #
echo "Creating data directory"
mkdir -p "$bench_root_dir/data"

echo "Done!"
