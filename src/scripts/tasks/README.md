# RECOMB-CG Plasmid binning new approach with multi-flow

>[!WARNING]
> This is a old README I wrote.
> It may help you to have an overview of the tasks.

---

* [PlasBin Hierarchical Multi Flow (PB-HMF)](#plasbin-hierarchical-multi-flow-pb-hmf)
  * [Installation](#installation)
  * [Usage](#usage)
* [gplasCC](#gplascc)
  * [Installation](#installation-1)
  * [Usage: default (automatically use plasmidCC as a classifier)](#usage-default-automatically-use-plasmidcc-as-a-classifier)
  * [Usage: with a custom classifier (other than plasmidCC)](#usage-with-a-custom-classifier-other-than-plasmidcc)
    * [From PlasBin-flow plasmidness TSV file](#from-plasbin-flow-plasmidness-tsv-file)
    * [From RFPlasmid](#from-rfplasmid)
  * [Convert gplasCC results to PlasBin-flow format](#convert-gplascc-results-to-plasbin-flow-format)
* [plasmidCC](#plasmidcc)
  * [Installation](#installation-2)
  * [Usage](#usage-1)
  * [Convert plasmidCC output to PBf plasmidness TSV file](#convert-plasmidcc-output-to-pbf-plasmidness-tsv-file)
* [Filtering the PlasBin-flow/HMF binning results to mimic GplasCC outputs](#filtering-the-plasbin-flowhmf-binning-results-to-mimic-gplascc-outputs)
* [Formatting data](#formatting-data)
  * [Installation](#installation-3)
  * [Usage](#usage-2)
* [Subsampling the dataset](#subsampling-the-dataset)
* [Getting reports from PlasEval evaluations](#getting-reports-from-plaseval-evaluations)

---

> [!Note]
> See the `todo.md` file

## PlasBin Hierarchical Multi Flow (PB-HMF)

### Installation

> [!Note]
> The tool is currently among other programs and does not benefit from a clean package.

Clone the GitHUB repository:

```bash
git clone https://github.com/AlgoLab/pangebin.git
cd pangebin
```

Create and source a virtual environment (Python>=3.11):

```bash
python3.11 -m virtualenv .venv_pb_hmf
source .venv_pb_hmf/bin/activate
```

Install PlasBin-HMF:

```bash
python3.11 -m pip install .
```

Test installation:

```bash
pangebin --help
```

### Usage

```bash
pangebin asm-pbf hmf --help
```

The subcommand `asm-pbf` ensures the next subcommands take as input the same files as in PlasBin-flow and output the same format.

```bash
pangebin asm-pbf hmf "$ASSEMBLY_GFA" "$SEED_CONTIGS_TSV" "$CONTIG_PLASMIDNESS_TSV" --outdir "$OUTPUT_DIR" --bin-cfg "$BIN_CONFIG_YAML" --gurobi-cfg "$GUROBI_CONFIG_YAML"
```

Where:

* `$ASSEMBLY_GFA` is the path to the assembly in GFA format.
* `$SEED_CONTIGS_TSV` is the path to the file with the seed contigs.
* `$CONTIG_PLASMIDNESS_TSV` is the path to the file with the contig plasmidness.
* `$OUTPUT_DIR` is the path to the output directory.
* `$BIN_CONFIG_YAML` is the path to the bin configuration file (example in `configs/hmf_config.yaml`).
* `$GUROBI_CONFIG_YAML` is the path to the Gurobi configuration file (example in `configs/gurobi_config.yaml`).

The run results in a file `$OUTPUT_DIR/bins.tsv` with the bins in the PlasBin-flow format.

## gplasCC

### Installation

Refer to `envs/gplascc/README.md`.

### Usage: default (automatically use plasmidCC as a classifier)

Refer to the template `scripts/templates/run_gplascc_default.sh`.

### Usage: with a custom classifier (other than plasmidCC)

Refer to the template `scripts/templates/run_gplascc_custom.sh`.

First, be sure the classification result has been formatted for gplasCC, see the following subsections.

#### From PlasBin-flow plasmidness TSV file

Activate first the PlasBin-HMF Python environment to use the format script (see [PlasBin-HMF installation](#installation)).

```bash
python3 scripts/format.py pbf-plm-to-gplascc-input "$PLASMIDNESS_TSV" "$ASM_GFA" "$OUT_TAB"
```

Where:

* `$PLASMIDNESS_TSV`: path to the PlasBin-flow plasmidness TSV file
* `$ASM_GFA`: path to the (zipped) assembly graph (`gfa.gz` format)
* `$OUT_TAB`: (output) path to the gplasCC input classification file

#### From RFPlasmid

In two steps:

1. convert RFPlasmid classification results to PBf plasmidness TSV file;
2. convert PBf plasmidness TSV file to gplasCC input classification format (see [From PlasBin-flow plasmidness TSV file](#from-plasbin-flow-plasmidness-tsv-file)).

### Convert gplasCC results to PlasBin-flow format

Activate first the PlasBin-HMF Python environment to use the format script (see [PlasBin-HMF installation](#installation)).

```bash
python3 py_scripts/format.py gplascc-to-bins-tsv "$GPLASCC_RES_TAB" "$BINS_TSV" # --keep_unbinned
```

Where:

* `$GPLASCC_RES_TAB`: path to the gplasCC result tab file (ex: `$output_dir/results/${out_prefix}_results.tab`, see `scripts/templates/run_gplascc_default.sh`)
* `$BINS_TSV`: path to the output bins.tsv file (PlasBin-flow format)
* Option `--keep_unbinned`: keep the unbinned contigs (a new bin named "Unbinned" will appear in the bins file)

## plasmidCC

### Installation

Refer to `envs/plasmidcc/README.md`.

### Usage

Refer to the template `scripts/templates/run_plasmidcc.sh`.

### Convert plasmidCC output to PBf plasmidness TSV file

Activate first the PlasBin-HMF Python environment to use the format script (see [PlasBin-HMF installation](#installation)).

```bash
python3 scripts/format.py plasmidcc-to-pbf "$PLMCC_TXT" "$PLASMIDNESS_TSV"
```

Where:

* `$PLMCC_TXT`: (input) path to the PlasmidCC output file (for example with suffix `*_centrifuge_classified.txt`)
* `$PLASMIDNESS_TSV`: (output) path to the PlasBin-flow plasmidness TSV file

## Filtering the PlasBin-flow/HMF binning results to mimic GplasCC outputs

See `scripts/filter_pbf_bins.py`

Requires to have a virtual environment with `pangebin` installed (test with `pangebin --help`).

```bash
python3 ./scripts/filter_pbf_bins.py rm-low-plm "$BINS_TSV" "$CONTIG_PLASMIDNESS_TSV" "$SEED_CONTIGS_TSV" "$NEW_BINS_TSV" --plm-thr "$PLASMIDNESS_THRESHOLD"
```

Where:

* `$BINS_TSV`: path to the bins.tsv file (ex: `${OUTPUT_DIR}/bins.tsv`)
* `$CONTIG_PLASMIDNESS_TSV`: path to the plasmidness.tsv file
* `$SEED_CONTIGS_TSV`: path to the seeds.tsv file
* `$NEW_BINS_TSV`: path to the new bins.tsv file (ex: `${OUTPUT_DIR}_filtered/bins.tsv`)
* `$PLASMIDNESS_THRESHOLD`: plasmidness threshold (set to `0.5` if you want the default)

## Formatting data

### Installation

Need the PlasBin-HMF Python environment to use the format script (see [PlasBin-HMF installation](#installation)).

### Usage

```bash
python3 scripts/format.py --help
```

## Subsampling the dataset

See `scripts/subsamples`.

```bash
# Create a virtual environment with Python 3.13
python3.13 -m virtualenv scripts/venv313
source scripts/venv313/bin/activate
pip install -r scripts/subsamples/requirements.txt
python3.13 scripts/subsamples/__main__.py --help
```

Run the tool:

```bash
python3 scripts/subsamples/__main__.py "$FULL_SAMPLES_TSV" "$TGT_DATA_DIR" "$NUMBER_OF_SAMPLES" > subsamples_stats.log
```

It will create a file `$TGT_DATA_DIR/samples.tsv` with the `$NUMBER_OF_SAMPLES` subsamples from the `$FULL_SAMPLES_TSV` file.

> [!Note]
> `$TGT_DATA_DIR/samples.tsv` contains a new first column `uid` equals to `$species_id-$sample_id`

## Getting reports from PlasEval evaluations

Refer to [plaseval_report-py/README.md](./plaseval_report-py/README.md)
