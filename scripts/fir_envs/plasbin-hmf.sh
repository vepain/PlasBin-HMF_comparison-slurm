#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Installation of PlasBin-HMF
# ---------------------------------------------------------------------------- #
BENCH_ROOT_DIR=$(realpath "$1")
# shellcheck source=../../src/scripts/config.sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"

running_dir=$(pwd)

umask 007

# ---------------------------------------------------------------------------- #
# Build the compute canada wheel for gurobipy
# ---------------------------------------------------------------------------- #
cd "/scratch/$USER" || exit 1
mkdir gurobi-wheel
cd gurobi-wheel || exit 1

wget https://raw.githubusercontent.com/ComputeCanada/wheels_builder/main/unmanylinuxize.sh
chmod u+rx unmanylinuxize.sh
wget https://raw.githubusercontent.com/ComputeCanada/wheels_builder/main/manipulate_wheels.py
chmod u+rx manipulate_wheels.py

./unmanylinuxize.sh --package gurobipy --version 13.0.2 --url https://files.pythonhosted.org/packages/a5/11/77458930745fb661a0b5aea39211101a22c5413161bb10f954f015af3f70/gurobipy-13.0.2-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl

#
# Finish
#
mv ./gurobipy-13.0.2+computecanada-cp313-cp313-linux_x86_64.whl "$BENCH_ENVS_DIR"
cd ..
# Remove the working dir
rm -rf gurobi-wheel
cd "$running_dir" || exit 1
