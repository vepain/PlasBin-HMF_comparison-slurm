---
icon: lucide/download
---

# Pipeline prelude

`scripts/prelude/prelude.sh` downloads every SRA run of `completed_samples.csv` (short and
long reads, 2482 runs) in one go, instead of each assembly task fetching its own.

Like every benchmark script it reads its paths from `filetree_layout.sh`: the runs land
in `$SRA_DIR` (`data/prelude/sra`), one `get_sra_dir` per run. Only `BENCH_ROOT_DIR` has
to be set, the remaining user variables are right below it.

!!! warning "Not an sbatch script"

    Run it on a login or data transfer node. It is network bound: inside an sbatch
    job it would hold a compute allocation idle while waiting on the NCBI side.

=== ":lucide-file-terminal: Bash"

    ```bash
    work_dir="/scratch/$USER/prelude"
    mkdir -p "$work_dir"

    cp scripts/prelude/prelude.sh "$work_dir"
    cd "$work_dir"
    ```

=== ":lucide-fish: Fish"

    ```fish
    set work_dir "/scratch/$USER/prelude"
    mkdir -p "$work_dir"

    cp scripts/prelude/prelude.sh "$work_dir"
    cd "$work_dir"
    ```

Launch it (`nohup`, or any way that survives the session: it runs for hours):

```sh
nohup ./prelude.sh > prelude.log 2>&1 &
```

Each run lands in `get_sra_dir`, the directory `fasterq-dump` takes to extract the
FASTQ later. `prefetch` leaves the runs it already has alone, so re-run the script to
retry whatever failed.

The [assembly scripts](assembly.md) read `$SRA_DIR` too. They do not have to wait for the download to end, see
[launching on a partial prelude](assembly.md#launching-on-a-partial-prelude). Once every assembly is done, `$SRA_DIR` can be deleted.

??? info "Script"

    ```sh title="scripts/prelude/prelude.sh"
    --8<-- "src/scripts/prelude/prelude.sh"
    ```

## Removing the runs once assembled

`scripts/prelude/delete_ready.sh` deletes the runs whose assemblies exist, so the
prelude does not have to be kept whole until the end:

```sh
./delete_ready.sh
```

A run goes only once **every** assembly reading it is there -- the long run is read by
the hybrid assembly, the short one by both -- and a run shared by two samples waits for
both. Samples held by a pending or running task keep their runs -- any job whose name starts
with `asm_short` or `asm_hybrid`, see
[the prefix rule](assembly.md#launching-on-a-partial-prelude). That is why this is a
pass of its own rather than an `rm` at the end of an assembly script: a task cannot know
whether the other assembly has run.

### Short-read assemblies only

If no hybrid assembly is planned, nothing will ever read the long runs, and the short
runs would wait forever for a hybrid assembly that is not coming:

```sh
./delete_ready.sh --only-short
```

A short run then waits for its short-read assembly alone, and **the long runs are
deleted straight away**, whatever the assemblies look like. It is the biggest sweep the
script can make -- the Oxford Nanopore runs are the bulky ones -- so run it only once
the decision is made. Getting them back means deleting their markers and running the
prelude again.

### Markers

Each deleted run leaves a `get_sra_done_marker` beside it, which `prelude.sh` skips, so a later prelude does not download it again. Delete the marker to get the run
back. The assembly is the marker on its side: `submit_ready.sh` skips an assembled
sample before it ever looks at the prelude.

Together they make the prelude and the assemblies a one-shot stage: once a sample is
assembled its runs are gone, and neither script picks it up again.

??? info "Script"

    ```sh title="scripts/prelude/delete_ready.sh"
    --8<-- "src/scripts/prelude/delete_ready.sh"
    ```
