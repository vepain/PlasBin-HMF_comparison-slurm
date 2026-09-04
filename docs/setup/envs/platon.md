# Installation Platon

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

In your Fir `PlasBin-HMF_comparison-slurm` directory:

```sh
chmod +x scripts/fir_envs/platon/build_apptainer_sif.sh
./scripts/fir_envs/platon/build_apptainer_sif.sh "$benchmark_root_dir"
```

The script build a apptainer image.

??? info "Script"

    ```sh title="scripts/fir_envs/platon/build_apptainer_sif.sh"
    --8<-- "scripts/fir_envs/platon/build_apptainer_sif.sh"
    ```

!!! note

    When `apptainer run` is used with `sbatch`, the following options may be required:

    - `-B`: see <https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts_and_persistent_overlays>
    - `-W "$SLURM_TMPDIR"`: see <https://docs.alliancecan.ca/wiki/Apptainer#Important_command_line_options>
