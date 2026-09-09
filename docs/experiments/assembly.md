---
icon: lucide/dna
---

# Assembly

The assembly scripts read the raw sample list `hyplas_samples.tsv`
(`$SRA_SAMPLES_TSV`, see [the filetree](filtree.md)), *not* `completed_samples.csv`:
they run before the assembly filtering step that produces the latter.

Required columns:

| Column       | Description                                     |
| ------------ | ----------------------------------------------- |
| `species_id` | Species code (`abau`, `ecol`, ...)              |
| `sample_id`  | BioSample accession                             |
| `sra_sr`     | SRA accession for short reads                   |
| `sra_lr`     | SRA accession for long reads                    |

`species_id` and `sample_id` are the same pair as in `completed_samples.csv`, so the
assemblies are keyed by the benchmark-wide `smp_uid` (`${species_id}-${sample_id}`)
that every downstream step expects.

## Unicycler hybrid assembly

!!! warning

    The sbatch script requires `envs/unicycler.sif` to be built beforehand.

The reads are downloaded from the SRA into `$SLURM_TMPDIR` and discarded with it;
only `assembly.fasta.gz` and `assembly.gfa.gz` are kept
(see `get_unicycler_hybrid_assembly_dir`).

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

Set `--array` to `2-$(( $(wc -l < hyplas_samples.tsv) ))` (line 1 is the header),
then launch the slurm job:

```sh
sbatch asm_hybrid_reads.sh
```
