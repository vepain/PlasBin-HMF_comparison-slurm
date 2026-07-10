# Installation PlasEval (Gianluca Della Vedova's fork)

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

In your Fir `PlasBin-HMF_comparison-slurm` directory:

```sh
chmod +x scripts/fir_envs/plaseval-gdv.sh
./scripts/fir_envs/plaseval-gdv.sh
```

??? info "Script"

    ```sh title="scripts/fir_envs/plaseval-gdv.sh"
    --8<-- "scripts/fir_envs/plaseval-gdv.sh"
    ```

!!! note

    When `apptainer run` is used with `sbatch`, the following options may be required:

    - `-B`: see <https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts_and_persistent_overlays>
    - `-W "$SLURM_TMPDIR"`: see <https://docs.alliancecan.ca/wiki/Apptainer#Important_command_line_options>
