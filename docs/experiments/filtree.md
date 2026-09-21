---
icon: lucide/folder-tree
---

# Experiment filetree structure

The script `$BENCH_ROOT_DIR/scripts/filetree_layout.sh` defines the filetree architecture of the experiments, summarized in the following code block:

```sh
📂 BENCH_ROOT_DIR
├── 📄 completed_samples.csv
├── 📁 scripts
├── 📁 envs
└── 📂 data
    ├── 📂 ground_truths    # $GROUND_TRUTH_DIR
    │   └── 📂 {smp_uid}
    │       └── 📄 short.gfa.csv    # get_gt_csv
    ├── 📂 prelude  # $PRELUDE_DIR
    │   └── 📂 sra  # $SRA_DIR
    │       ├── 📂 {sra_id}     # get_sra_dir
    │       │   └── 📄 {sra_id}.sra
    │       └── 📄 {sra_id}.done    # get_sra_done_marker
    ├── 📂 assembly_files   # split by read set first, assembler second
    │   ├── 📂 short
    │   │   └── 📂 unicycler    # $UNI_SHORT_ASSEMBLY_DIR
    │   │       └── 📂 {smp_uid}    # get_unicycler_short_assembly_dir
    │   │           ├── 📄 assembly.fasta.gz
    │   │           └── 📄 assembly.gfa.gz  # get_unicycler_assembly_gfa_gz
    │   └── 📂 hybrid
    │       └── 📂 unicycler    # $UNI_HYBRID_ASSEMBLY_DIR
    │           └── 📂 {smp_uid}    # get_unicycler_hybrid_assembly_dir
    │               ├── 📄 assembly.fasta.gz
    │               └── 📄 assembly.gfa.gz
    └── 📂 results
        ├── 📂 rfplasmid
        │   └── 📂 unicycler    # $UNI_RFPLASMID_DIR
        │       └── 📁 {smp_uid}    # get_rfplasmid_out_dir
        ├── 📂 platon
        │   └── 📂 unicycler    # $UNI_PLATON_DIR
        │       └── 📁 {smp_uid}    # get_platon_out_dir
        ├── 📂 formatted_input
        │   └── 📂 unicycler    # $UNI_FORMATTED_INPUT_DIR
        │       ├── 📂 rfplasmid
        │       │   ├── 📂 input_pbf
        │       │   │   └── 📄 {smp_uid}_scores.tsv     # get_plm_pbf_rfpl_tsv
        │       │   └── 📂 input_gplas
        │       │       └── 📄 {smp_uid}_scores.tsv     # get_plm_gplas_rfpl_tsv
        │       └── 📂 platon
        │           └── 📂 input_pbf
        │               └── 📄 {smp_uid}_seeds.tsv      # get_seeds_pbf_platon_tsv
        ├── 📂 binning
        │   └── 📂 unicycler    # $UNI_BIN_DIR
        │       └── 📂 {method_code}
        │           └── 📂 {smp_uid}    # get_uni_bin_dir
        │               ├── 📄 bins.tsv                 # get_pbf_bin_pred
        │               ├── 📄 plasbin_flow_bins.tsv    # get_pbhmf_pbf_bin_pred
        │               ├── 📄 bins.tab                 # get_gpcc_bin_pred
        │               └── 📄 contig_report.txt        # get_mob_bin_pred
        ├── 📂 formatted_bins
        │   └── 📂 unicycler
        │       ├── 📂 predictions  # $UNI_PLASEVAL_PRED_BINS_DIR
        │       │   └── 📂 {method_code}
        │       │       └── 📄 {smp_uid}.tsv    # get_pred_plaseval_fmt
        │       └── 📂 ground_truths    # $UNI_PLASEVAL_GT_BINS_DIR
        │           └── 📄 {smp_uid}.tsv    # get_gt_plaseval_fmt
        ├── 📂 repeat_stats
        │   └── 📂 unicycler
        │       └── 📄 ground_truths.tsv    # $UNI_REPEAT_STATS_GT_TSV
        └── 📂 plaseval_gdv
            └── 📂 unicycler
                ├── 📂 comp # $UNI_PLASEVAL_GDV_COMP_DIR
                │   └── 📂 alpha_{alpha_value}  # get_plaseval_comp_alpha_dir
                │       ├── 📁 merged   # get_plaseval_comp_merge_dir
                │       └── 📂 {method_code}    # get_plaseval_comp_alpha_meth_dir
                │           ├── 📄 {smp_uid}.out    # get_plaseval_comp_out
                │           └── 📄 {smp_uid}.log    # get_plaseval_comp_log
                └── 📂 eval # UNI_PLASEVAL_GDV_EVAL_DIR
                    └── 📂 {method_code}
                        ├── 📁 merged   # get_plaseval_eval_merge_dir
                        ├── 📄 {smp_uid}.out    # get_plaseval_eval_out
                        └── 📄 {smp_uid}.log    # get_plaseval_eval_log
```

## Rooting the tree

Every path above hangs off `$BENCH_ROOT_DIR`, the directory
[`init.sh`](../setup/init.md) populated. Scripts get it in one of two ways:

Every script carries the same line near its top:

```sh
BENCH_ROOT_DIR="TODO:BENCH_ROOT_DIR"
```

[`init.sh`](../setup/init.md) replaces that token with your benchmark directory in every
`.sh` it installs, so there is nothing to fill in by hand -- and a script copied out of
`$BENCH_ROOT_DIR/scripts` keeps the value. It is the only thing that comes from outside:
`config.sh` sources `filetree_layout.sh` with it, and every other path is derived.

```sh
source "$BENCH_ROOT_DIR/scripts/config.sh" "$BENCH_ROOT_DIR"
```

## The prelude subtree

The SRA runs are the one part of the tree that is temporary -- it is filled before the
assemblies and emptied after them:

| Name | What it is | Written by | Read by |
| ---- | ---------- | ---------- | ------- |
| `$PRELUDE_DIR` | `data/prelude`, everything the prelude stage holds | -- | -- |
| `$SRA_DIR` | `data/prelude/sra`, one directory per downloaded run | [`prelude.sh`](prelude.md) | -- |
| `get_sra_dir` | a run's directory, `<run id>.sra` and its reference files | `prefetch` | `fasterq-dump`, in the [assembly scripts](assembly.md) |
| `get_sra_done_marker` | `<run id>.done`, left when a run is deleted | [`delete_ready.sh`](prelude.md#removing-the-runs-once-assembled) | `prelude.sh`, which skips a marked run |

A run is downloaded once for the whole benchmark, shared by the short-read and the
hybrid assembly of a sample -- and by two samples when they list the same accession.
Deleting `$PRELUDE_DIR` once the assemblies exist costs nothing but the markers: the
assemblies themselves are what every downstream step reads.
