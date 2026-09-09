# Installation Unicycler

!!! warning

    This is valid for the Alliance Canada Fir Cluster only, adapt for your cluster if needed

In your Fir `PlasBin-HMF_comparison-slurm` directory:

```sh
chmod +x scripts/fir_envs/unicycler/build_apptainer_sif.sh
./scripts/fir_envs/unicycler/build_apptainer_sif.sh "$benchmark_root_dir"
```

The script builds an apptainer image from the [StaPH-B Unicycler image](https://hub.docker.com/r/staphb/unicycler),
pinned to version 0.5.1.

??? info "Script"

    ```sh title="scripts/fir_envs/unicycler/build_apptainer_sif.sh"
    --8<-- "scripts/fir_envs/unicycler/build_apptainer_sif.sh"
    ```

??? info "Apptainer definition"

    ```sh title="scripts/fir_envs/unicycler/apptainer_img.def"
    --8<-- "scripts/fir_envs/unicycler/apptainer_img.def"
    ```

!!! note

    The image also ships SPAdes, Racon and miniasm, so `%runscript` is a plain
    passthrough: the sbatch script names the command itself
    (`apptainer run "$APPTAINER_IMG" unicycler ...`).

!!! note

    `prefetch` and `fastq-dump` are **not** in the image: `src/envs/unicycler.sh`
    loads them from the cluster's `sra-toolkit` module.
