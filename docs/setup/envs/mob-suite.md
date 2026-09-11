# Installation MOB-suite

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

In your Fir `PlasBin-HMF_comparison-slurm` directory, on a login node (the build
downloads the MOB-suite databases):

```sh
chmod +x scripts/fir_envs/mob-suite/build_apptainer_sif.sh
./scripts/fir_envs/mob-suite/build_apptainer_sif.sh "$benchmark_root_dir"
```

The script builds `envs/mob-suite.sif` from the
[MOB-suite 3.1.9 biocontainer](https://quay.io/repository/biocontainers/mob_suite), with
the databases installed by `mob_init` in `/opt/mob_db` inside the image. The sbatch
script passes that directory to `mob_recon --database_directory`: with a non-default
directory MOB-recon only reads from it, which a read-only image allows.

??? info "Script"

    ```sh title="scripts/fir_envs/mob-suite/build_apptainer_sif.sh"
    --8<-- "scripts/fir_envs/mob-suite/build_apptainer_sif.sh"
    ```

??? info "Apptainer definition"

    ```sh title="scripts/fir_envs/mob-suite/apptainer_img.def"
    --8<-- "scripts/fir_envs/mob-suite/apptainer_img.def"
    ```
