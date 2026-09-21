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
already downloaded into `$prelude_dir` (`$BENCH_ROOT_DIR/prelude`, set at the top of
both scripts -- move it there if you moved the prelude's `$OUTPUT_DIR`). They extract
the FASTQ into `$SLURM_TMPDIR`, which is discarded with the task; only
`assembly.fasta.gz` and `assembly.gfa.gz` are kept.

!!! warning

    Run [`scripts/prelude.sh`](prelude.md) first: a sample whose runs are missing from
    `$prelude_dir` fails its task.

!!! warning

    Both sbatch scripts require `envs/unicycler.sif` to be built beforehand,
    see [the build script](../setup/envs/unicycler.md).

## Launching on a partial prelude

The assemblies do not have to wait for the whole prelude: `scripts/unicycler/submit_ready.sh`
submits an assembly script over the samples whose runs are already downloaded, and
leaves out the samples already assembled, so it can be run again in waves as the
prelude progresses.

```sh
./submit_ready.sh asm_short_reads.sh   # or asm_hybrid_reads.sh, which needs both runs
```

A resubmitted sample starts SPAdes from scratch: both assembly scripts delete a
`spades_assembly/` left by a crashed task, which Unicycler would otherwise resume from.

!!! warning "Keep the `asm_short` / `asm_hybrid` prefix"

    A copy of an assembly script with bigger `--mem` or `--cpus-per-task` writes the
    same tree as the original, so `submit_ready.sh` and `delete_ready.sh` must see its
    tasks in the queue. They match queued jobs on the `asm_short` / `asm_hybrid` name
    prefix, the job name being the script filename. Name a variant
    `asm_short_reads_64g.sh` and it is seen; name it `unicycler_64g.sh` and it is
    invisible -- the next launch resubmits the samples it is already assembling.

It restricts `--array` to the ready rows -- the array index is the line number of the
sample in `completed_samples.csv`. A run still being downloaded (`prefetch` leaves a
`.sra.lock` next to it) counts as not ready: a task reading it would assemble a
truncated read set.

??? info "Script"

    ```sh title="scripts/unicycler/submit_ready.sh"
    --8<-- "src/scripts/unicycler/submit_ready.sh"
    ```

## Unicycler short-read assembly

Writes to `get_unicycler_assembly_dir`, so that `get_unicycler_assembly_gfa_gz` --
the input of every classification and binning script -- resolves.

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
