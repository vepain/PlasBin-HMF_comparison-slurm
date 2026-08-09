# Apptainer image for gplasCC (Fir Alliance cluster)

Create conda environment configuration file `conda_env.yaml`

Create the apptainer definition file `apptainer_img.def`

Compress (with `tar`) and transfer the file with `scp` (otherwise, `git clone` in `fir` cluster and to the `scratch` directory)

```bash
cd envs
tar -czf gplascc.tar.gz gplascc
scp gplascc.tar.gz fir:/home/$yourname/scratch
```

Connect to a node on the `fir` cluster:

```bash
ssh fir
salloc --time=3:0:0 --mem=4G --cpus-per-task=4 --ntasks=1 --account=def-chauvec

cd scratch
tar -xzf gplascc.tar.gz -C .
cd gplascc
```

Build the apptainer image on `fir` cluster (on scratch):

```bash
module load apptainer
APPTAINER_BIND=" "
apptainer build apptainer_gplascc.sif apptainer_img.def
```

Test the apptainer image:

```bash
apptainer run -C apptainer_gplascc.sif gplas --help
```

Move it to the `/project/def-chauvec/wg-anoph/benchmarking/ENVS` directory:

```bash
mv apptainer_gplascc.sif /project/def-chauvec/wg-anoph/benchmarking/ENVS
```

> [!Note]
> When `apptainer run` is used with `sbatch`, the following options may be required:
>
> * `-B`: see <https://docs.alliancecan.ca/wiki/Apptainer#Bind_mounts_and_persistent_overlays>
> * `-W "$SLURM_TMPDIR"`: see <https://docs.alliancecan.ca/wiki/Apptainer#Important_command_line_options>
