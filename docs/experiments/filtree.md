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
    ├── 📂 assembly_files
    │   └── 📂 unicycler    # $UNI_ASSEMBLY_DIR
    │       └── 📂 {smp_uid}
    │           └── 📄 assembly.gfa.gz  # get_unicycler_assembly_gfa_gz
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
        │       │   └── 📂 input_pbf
        │       │       └── 📄 {smp_uid}_scores.tsv     # get_plm_pbf_rfpl_tsv
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