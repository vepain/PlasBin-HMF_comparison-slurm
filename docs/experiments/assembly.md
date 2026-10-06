---
icon: lucide/dna
---

# Assembly

Both assembly scripts read `completed_samples.csv` (`$SAMPLES_CSV`, 1241 samples,
`--array=2-1242`), which carries one SRA accession per read type:

| Script | Reads | Columns |
| ------ | ----- | ------- |
| `asm_short_reads.sh` | Illumina | `short_reads` |
| `asm_hybrid_reads.sh` | Illumina + Oxford Nanopore | `short_reads`, `long_reads` |

Both scripts key their output by the benchmark-wide `smp_uid`
(`${species_id}-${sample_id}`).

Neither script downloads anything: both read the runs [the prelude](prelude.md) has
already downloaded into `$SRA_DIR`, resolved through `get_sra_dir` like every other
path of the benchmark. They extract the FASTQ into `$SLURM_TMPDIR`, which is discarded with the task; only
`assembly.fasta.gz` and `assembly.gfa.gz` are kept.

!!! warning

    Run [`scripts/prelude/prelude.sh`](prelude.md) first: a sample whose runs are
    missing from `$SRA_DIR` fails its task.

??? warning "Prior apptainer installation"

    Both sbatch scripts require `envs/unicycler.sif` to be built beforehand,
    see [the build script](../setup/envs/unicycler.md).

## Launching the assemblies

[`prelude.sh`](prelude.md) submits both scripts itself, over the samples whose runs are
already downloaded, so the assemblies start before the download ends. A resubmitted
sample starts SPAdes from scratch: both scripts delete a `spades_assembly/` left by a
crashed task, which Unicycler would otherwise resume from.

## Unicycler short-read assembly

Writes to `get_unicycler_short_assembly_dir`, the raw assembly [the prelude](prelude.md)
filters into `get_unicycler_assembly_gfa_gz` -- the input of every classification and
binning script.

Copy the script `scripts/unicycler/asm_short_reads.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/unicycler"
    mkdir -p "$work_dir"

    cp scripts/unicycler/asm_short_reads.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/unicycler"
    mkdir -p "$work_dir"

    cp scripts/unicycler/asm_short_reads.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch asm_short_reads.sh
```

??? info "Script"

    ```sh title="scripts/unicycler/asm_short_reads.sh"
    --8<-- "src/scripts/unicycler/asm_short_reads.sh"
    ```

## Unicycler hybrid assembly

Writes to `get_unicycler_hybrid_assembly_dir`, kept separate from the short-read
assemblies.

Copy the script `scripts/unicycler/asm_hybrid_reads.sh` to another place to modify it:

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/unicycler"
    mkdir -p "$work_dir"

    cp scripts/unicycler/asm_hybrid_reads.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/unicycler"
    mkdir -p "$work_dir"

    cp scripts/unicycler/asm_hybrid_reads.sh "$work_dir"
    cd "$work_dir"
    ```

Launch the slurm job:

```sh
sbatch asm_hybrid_reads.sh
```

??? info "Script"

    ```sh title="scripts/unicycler/asm_hybrid_reads.sh"
    --8<-- "src/scripts/unicycler/asm_hybrid_reads.sh"
    ```
