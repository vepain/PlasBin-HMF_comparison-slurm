# Installation format-binning-inputs

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

In your Fir `PlasBin-HMF_comparison-slurm` directory, on a login node:

```sh
chmod +x scripts/fir_envs/format-binning-inputs/build_apptainer_sif.sh
./scripts/fir_envs/format-binning-inputs/build_apptainer_sif.sh "$benchmark_root_dir"
```

The script builds `envs/format-binning-inputs.sif`: a micromamba image whose base conda environment
holds gplas, plasmidCC and centrifuge (see `conda_env.yaml` and `requirements.txt`).

??? info "Script"

    ```sh title="scripts/fir_envs/format-binning-inputs/build_apptainer_sif.sh"
    --8<-- "scripts/fir_envs/format-binning-inputs/build_apptainer_sif.sh"
    ```

??? info "Apptainer definition"

    ```sh title="scripts/fir_envs/format-binning-inputs/apptainer_img.def"
    --8<-- "scripts/fir_envs/format-binning-inputs/apptainer_img.def"
    ```

Check the image:

```sh
apptainer run -C envs/format-binning-inputs.sif --help
```
