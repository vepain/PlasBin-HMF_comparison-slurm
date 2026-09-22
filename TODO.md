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

## Pipeline prelude

* [ ] Download all the SRAs in once (short and long)
* [ ] Assemblies with Unicycler (short and hybrid)
  * [ ] We may have several sbatch script with increasing memory/cpus parameters
* [ ] Remove the SRAs
* [ ] Filter the short-contig assemblies
* [ ] Remove the unfiltered short-contig assemblies

### Short read assembly (unfiltered)

* [x] `src/scripts/unicycler/asm_short_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

### Filter short read assemblies

* [ ] `???`
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

<!-- FIXME change the function to assembly graphs and FASTA (filtered one for classification and binning) -->

### Hybrid assembly

* [x] `src/scripts/unicycler/asm_hybrid_reads.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

### Filter uncompleted hybrid assembly

* [ ] [👤 @vepain] Find Tomas' script(s), otherwise recode
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

Process:

* [ ] Label each hybrid assembly
  * `gfa.gz` -> `labels.tsv`
* [ ] Filter sample list
  * complete sample TSV + TSV file `<sample_uid>  <labels_tsv>` -> sub complete sample TSV

## Generate ground truth

* [ ] [👤 @vepain] Find Tomas' script(s), otherwise recode
  * [ ] 🧰
  * [ ] 🗃️
  * [ ] 🚧
  * [ ] 🧪
  * [ ] 📑

Process (for each sample in the only labelled hybrid contig sample list):

* [ ] Map short vs hybrid contigs
* [ ] Label short contigs according to mapping result
  * `bam` -> `labels.tsv`

Candiate script: `/project/6001426/wg-anoph/benchmarking/scripts/ground-truth-new-v2.pl`

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

### Prepare inputs

#### PlasBin-flow inputs

* [x] RFPlasmid PBF plasmidness
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] Platon PBF seeds
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

#### gplasCC inputs

* [x] RFPlasmid gplasCC classification
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑

### Run

* [x] [👤 @vepain] `plasbin-hmf`
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
* [x] `src/scripts/merge-plaseval/merge_eval.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
  * [x] 📑
* [x] `src/scripts/merge-plaseval/merge_comp.sh`
  * [x] 🧰
  * [x] 🗃️
  * [x] 🚧
  * [x] 🧪
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
