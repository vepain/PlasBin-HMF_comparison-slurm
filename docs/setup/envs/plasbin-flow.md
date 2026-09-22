# Installation PlasBin-flow

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

PlasBin-flow needs Gurobi, loaded from the Fir `gurobi` module: the same access as
[PlasBin-HMF](plasbin-hmf.md).

In your Fir `PlasBin-HMF_comparison-slurm` directory, on a login node (the script clones
the repository and installs wheels):

```sh
chmod +x scripts/fir_envs/plasbin-flow.sh
./scripts/fir_envs/plasbin-flow.sh "$benchmark_root_dir"
```

The script clones [PlasBin-flow](https://github.com/cchauve/PlasBin-flow) at a pinned
commit into `envs/plasbin-flow/PlasBin-flow` and builds the virtual environment
`envs/plasbin-flow/venv` (Python 3.13, `gurobipy` 13.0.2 and the packages PlasBin-flow's
code imports).

??? info "Script"

    ```sh title="scripts/fir_envs/plasbin-flow.sh"
    --8<-- "scripts/fir_envs/plasbin-flow.sh"
    ```
