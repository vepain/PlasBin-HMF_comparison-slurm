---
status: deprecated
---

# Installation PlasBin-HMF

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

In your Fir `PlasBin-HMF_comparison-slurm` directory:

```sh
chmod +x scripts/fir_envs/plasbin-hmf.sh
./scripts/fir_envs/plasbin-hmf.sh "$benchmark_root_dir"
```

The script build a custom gurobipy wheel for the Alliance Canada Fir Cluster.

??? info "Script"

    ```sh title="scripts/fir_envs/plasbin-hmf.sh"
    --8<-- "scripts/fir_envs/plasbin-hmf.sh"
    ```
