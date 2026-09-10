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

In both scripts the reads are downloaded into `$SLURM_TMPDIR` and discarded with it;
only `assembly.fasta.gz` and `assembly.gfa.gz` are kept.

!!! warning

    Both sbatch scripts require `envs/unicycler.sif` to be built beforehand,
    see [the build script](../setup/envs/unicycler.md).

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
