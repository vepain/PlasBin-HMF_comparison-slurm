# To-do

> [!IMPORTANT]
> Check the task when the script has been tested on the cluster.
>
> Sub-tasks:
>
> * 🧰 (optionnal) the Fir environment script is written
> * 🗃️ the sbatch environment script loader is written
> * 🚧 the sbatch script is written
> * 🧪 sbatch script tested on HPC Fir cluster
> * 📑 sbatch script usage documented
>
> Follow the [CONTRIBUTING](CONTRIBUTING.md) guidelines.

## Short read assembly

* [x] `src/scripts/unicycler/asm_short_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Hybrid assembly

* [x] `src/scripts/unicycler/asm_hybrid_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Filter uncompleted hybrid assembly

* [ ] [👤 @msgr0] `src/scripts/ground-truth/filter_complete_samples.sh` (recoded: the rule
  is in none of Tomas' scripts, but was recovered from his 1241 `hybrid.gfa.csv`
  files — keep a sample iff no hybrid contig is `unlabeled`, which reproduces his
  836-sample list exactly)
  * [x] 🧰 (plain bash/awk, nothing to build)
  * [x] 🗃️ (no environment needed)
  * [x] 🚧
  * [x] 🧪 (rule validated against Tomas' 1241 label files: 836 kept, 0 disagreements;
    a run on our own data awaits the hybrid assemblies)
  * [ ] 📑

## Generate ground truth

* [ ] [👤 @msgr0] `src/scripts/ground-truth/uni_short_vs_hybrid.sh` (ported from Tomas' `ground-truth-new-v2.pl`)
  * [x] 🧰 (minimap2 is a module, nothing to build)
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [ ] 📑

## Classification

* [x] `src/scripts/rfplasmid/uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/platon/uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Binning

* [ ] [👤 @vepain] `plasbin-hmf`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] [👤 @msgr0] `src/scripts/gplascc/rfpl_uni.sh` (GplasCC + RFPlasmid)
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/mob-suite/uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/plasbin-flow/rfpl_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

## Evaluation

* [x] `src/scripts/format-plaseval/pred_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [ ] `src/scripts/format-plaseval/gt_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [ ] 📑
* [x] `src/scripts/plaseval-gdv/eval.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/plaseval-gdv/comp_uni.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [ ] `src/scripts/merge-plaseval/merge_eval.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [x] 📑
* [ ] `src/scripts/merge-plaseval/merge_comp.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [ ] 🧪
  * [x] 📑

## Figures

* [ ] [👤 @vepain] distributions
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
* [ ] [👤 @vepain] res-presence
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
* [ ] [👤 @vepain] repeat-stats
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑
