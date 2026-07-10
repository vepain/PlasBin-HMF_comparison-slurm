---
icon: lucide/rocket
---

# Initializing your benchmark

!!! important

    You must connect to your SLURM-based HPC cluster first.

```sh
git clone https://github.com/vepain/PlasBin-HMF_comparison-slurm.git
cd PlasBin-HMF_comparison-slurm
```

Set your benchmark directory on your HPC cluster:

```sh
benchmark_root_dir=/path/to/your/benchmark/directory
```

Initialize the benchmark environment:

```sh
./init.sh "$benchmark_root_dir"
```

## Overview

In `$benchmark_root_dir`, you will find the following directories:

| Directory | Description                                                                                   |
| --------- | --------------------------------------------------------------------------------------------- |
| `envs`    | Environment setup scripts for the tools (originally made for the Canada Alliance Fir Cluster) |
| `scripts` | sbatch scripts to run the experiments                                                         |
