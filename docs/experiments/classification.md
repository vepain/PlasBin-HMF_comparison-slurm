---
icon: lucide/tags
---

# Classification

Both classifiers run on the Unicycler short-read assemblies
(`get_unicycler_assembly_gfa_gz`, see [the filetree](filtree.md)) of the labelled
samples (`only_labelled_samples.tsv`). Each script rebuilds a FASTA from the GFA
segments in `$SLURM_TMPDIR`, so the contig names match the assembly graph.

## RFPlasmid

!!! warning

    The sbatch script requires `envs/RFPlasmid.sif`, see [the build script](../setup/envs/rfplasmid.md).

The RFPlasmid model is picked from the sample's `species_id`:

| `species_id` | RFPlasmid `--species` |
| ------------ | --------------------- |
| `ecol`, `kpne` | `Enterobacteriaceae` |
| `efae` | `Enterococcus` |
| `saur` | `Staphylococcus` |
| `paer` | `Pseudomonas` |
| `abau` | `Generic` (RFPlasmid has no Acinetobacter model) |

A sample with any other `species_id` fails instead of silently using the wrong model.

Copy the script `scripts/rfplasmid/uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/rfplasmid"
    mkdir -p "$work_dir"

    cp scripts/rfplasmid/uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/rfplasmid"
    mkdir -p "$work_dir"

    cp scripts/rfplasmid/uni.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch uni.sh
```

Results are written to `get_rfplasmid_out_dir` (`prediction.csv`, ...).

## Platon

!!! warning

    The sbatch script requires `envs/Platon.sif`, see [the build script](../setup/envs/platon.md).

Copy the script `scripts/platon/uni.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/platon"
    mkdir -p "$work_dir"

    cp scripts/platon/uni.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/platon"
    mkdir -p "$work_dir"

    cp scripts/platon/uni.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch uni.sh
```

Results are written to `get_platon_out_dir`, named after the sample
(`{smp_uid}.tsv`, `{smp_uid}.plasmid.fasta`, ...).
