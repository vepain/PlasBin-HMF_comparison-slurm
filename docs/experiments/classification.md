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

!!! warning "Resubmitting a task"

    If its `--out` directory already exists, RFPlasmid does not overwrite it: it
    writes to `{smp_uid}_YYYYMMDD_HHMMSS` next to it instead, which no downstream
    step reads. The sbatch script therefore never creates the output directory
    itself, but a **previous attempt** leaves one behind. Before resubmitting a
    sample, delete its directory:

    ```sh
    rm -rf "$benchmark_root_dir/data/results/rfplasmid/unicycler/$smp_uid"
    ```

    To recover results that already landed in timestamped directories, move them
    into place (`rmdir` only removes the empty directory left in the way, so a
    real result is never deleted):

    ```sh
    cd "$benchmark_root_dir/data/results/rfplasmid/unicycler"
    for d in *_20??????_??????; do u=${d%_*_*}; rmdir "$u" && mv "$d" "$u"; done
    ```

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
