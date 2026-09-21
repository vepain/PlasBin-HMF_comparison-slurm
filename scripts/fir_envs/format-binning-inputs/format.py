"""Format some files."""

# Due to typer usage:
# ruff: noqa: FBT002

from __future__ import annotations

import csv
from pathlib import Path
from typing import Annotated

import gfapy  # type: ignore[import-untyped]
import pangebin.gfa.iter as gfa_iter
import pangebin.pbf_comp.input_output as pbf_comp_io
import pangebin.pbf_comp.items as pbf_comp_items
import rich
import typer
from pangebin.gfa import input_output as gfa_io
from pangebin.gfa.assembler import ops as gfa_asm_ops
from pangebin.plasbin.hmf import results as hmf_res

APP = typer.Typer(
    name="format",
    help="Format some files.",
)


@APP.command("plasgraph2-to-pbf")
def plasgraph2_to_pbf(
    plasmid_probabilities_csv: Annotated[
        Path,
        typer.Argument(help="Path to the CSV file"),
    ],
    pbf_plasmidness_tsv: Annotated[
        Path | None,
        typer.Argument(help="Path to the pbf_plasmidness.tsv file"),
    ] = None,
) -> None:
    """Convert a plasmid_probabilities.csv file to a pbf_plasmidness.tsv file."""
    if pbf_plasmidness_tsv is not None:
        pbf_tsv = pbf_plasmidness_tsv
    else:
        pbf_tsv = plasmid_probabilities_csv.parent / "pbf_plasmidness.tsv"

    with (
        plasmid_probabilities_csv.open() as f_in,
        pbf_comp_io.PlmWriter.open(pbf_tsv) as pbf_writer,
    ):
        fin_reader = csv.reader(f_in, delimiter=",")
        iter_f_in = iter(fin_reader)
        next(iter_f_in)  # skip header
        for line in iter_f_in:
            contig_name = line[1]
            plm_score = float(line[3])
            pbf_writer.write_sequence_plasmidness(contig_name, plm_score)


@APP.command("plasmidcc-to-pbf")
def plasmidcc_to_pbf(
    classification_txt: Annotated[
        Path,
        typer.Argument(help="Path to the TXT (TSV) file"),
    ],
    pbf_plasmidness_tsv: Annotated[
        Path | None,
        typer.Argument(help="Path to the pbf_plasmidness.tsv file"),
    ] = None,
) -> None:
    """Convert a PlasmidCC classification file to a pbf_plasmidness.tsv file."""
    if pbf_plasmidness_tsv is not None:
        pbf_tsv = pbf_plasmidness_tsv
    else:
        pbf_tsv = classification_txt.parent / "pbf_plasmidness.tsv"

    with (
        classification_txt.open() as f_in,
        pbf_comp_io.PlmWriter.open(pbf_tsv) as pbf_writer,
    ):
        fin_reader = csv.reader(f_in, delimiter="\t")
        iter_f_in = iter(fin_reader)
        next(iter_f_in)  # skip header
        for line in iter_f_in:
            new_contig_name = line[0]
            contig_name = new_contig_name.split("_")[0][1:]
            plm_score = float(line[6])
            pbf_writer.write_sequence_plasmidness(contig_name, plm_score)


@APP.command("plasgraph2-to-gplascc-input")
def plasgraph2_to_gplascc_input(
    plasmid_probabilities_csv: Annotated[
        Path,
        typer.Argument(help="Path to the CSV file"),
    ],
    gfa_path: Annotated[
        Path,
        typer.Argument(help="Path to the GFA file"),
    ],
    output_file: Annotated[
        Path,
        typer.Argument(help="Path to the output file"),
    ],
) -> None:
    """Convert a plasmid_probabilities.csv file to a gplascc input file."""
    ctg_new_names: dict[str, str] = {}
    for sequence_line in gfa_iter.segment_lines(gfa_path):
        if not sequence_line.sequence:
            sequence_line.sequence = str(gfapy.Placeholder())
        seq_line_str_items = str(sequence_line).split()
        ctg_new_names[seq_line_str_items[1]] = (
            f"{seq_line_str_items[0]}{seq_line_str_items[1]}_"
            + "_".join(
                seq_line_str_items[3:],
            )
        )

    with plasmid_probabilities_csv.open() as f_in, output_file.open("w") as f_out:
        f_out_writer = csv.writer(f_out, delimiter="\t")
        f_out_writer.writerow(
            [
                "Prob_Chromosome",
                "Prob_Plasmid",
                "Prediction",
                "Contig_name",
                "Contig_length",
            ],
        )
        fin_reader = csv.reader(f_in, delimiter=",")
        iter_f_in = iter(fin_reader)
        next(iter_f_in)  # skip header
        for line in iter_f_in:
            ctg_name, ctg_len, plm_score, chrom_score, label = line[1:6]
            if label == "plasmid":
                new_label = "Plasmid"
            elif label == "chromosome":
                new_label = "Chromosome"
            elif plm_score >= chrom_score:
                new_label = "Plasmid"
            else:
                new_label = "Chromosome"
            new_name = ctg_new_names[ctg_name]
            f_out_writer.writerow(
                [
                    float(chrom_score),
                    float(plm_score),
                    new_label,
                    new_name,
                    int(ctg_len),
                ],
            )


@APP.command("rfplasmid-to-pbf-plm")
def rfplasmid_to_plasbinflow_plasmidness(
    rfplasmid_csv: Annotated[
        Path,
        typer.Argument(help="Path to the CSV file"),
    ],
    pbf_plasmidness_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the PBF plasmidness TSV file"),
    ],
) -> None:
    """Convert a plasmid_probabilities.csv file to a pbf_plasmidness.tsv file."""
    with (
        rfplasmid_csv.open() as f_in,
        pbf_comp_io.PlmWriter.open(pbf_plasmidness_tsv) as pbf_writer,
    ):
        fin_reader = csv.reader(f_in, delimiter=",")
        iter_f_in = iter(fin_reader)
        next(iter_f_in)  # skip header
        for line in iter_f_in:
            contig_name = line[4]
            plm_score = float(line[3])
            pbf_writer.write_sequence_plasmidness(contig_name, plm_score)


@APP.command("pbf-plm-to-gplascc-input")
def pbf_plm_to_gplascc_input(
    pbf_plasmidness_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the PBF plasmidness TSV file"),
    ],
    gfa_path: Annotated[
        Path,
        typer.Argument(help="Path to the GFA file"),
    ],
    output_file: Annotated[
        Path,
        typer.Argument(help="Path to the output file"),
    ],
) -> None:
    """Convert a plasmid_probabilities.csv file to a gplascc input file."""
    ctg_new_names_length: dict[str, tuple[str, int]] = {}
    for sequence_line in gfa_iter.segment_lines(gfa_path):
        if not sequence_line.sequence:
            sequence_line.sequence = str(gfapy.Placeholder())
        seq_line_str_items = str(sequence_line).split()
        ctg_new_names_length[seq_line_str_items[1]] = (
            f"{seq_line_str_items[0]}{seq_line_str_items[1]}_"
            + "_".join(
                seq_line_str_items[3:],
            ),
            len(sequence_line.sequence),
        )

    with (
        pbf_comp_io.PlmReader.open(pbf_plasmidness_tsv) as f_in,
        output_file.open("w") as f_out,
    ):
        f_out_writer = csv.writer(f_out, delimiter="\t")
        f_out_writer.writerow(
            [
                "Prob_Chromosome",
                "Prob_Plasmid",
                "Prediction",
                "Contig_name",
                "Contig_length",
            ],
        )
        for ctg_name, plm_score in f_in:
            chrom_score = 1 - plm_score
            new_label = "Plasmid" if plm_score > 0.5 else "Chromosome"
            new_name = ctg_new_names_length[ctg_name][0]
            ctg_len = ctg_new_names_length[ctg_name][1]
            f_out_writer.writerow(
                [
                    float(chrom_score),
                    float(plm_score),
                    new_label,
                    new_name,
                    int(ctg_len),
                ],
            )


@APP.command("gplascc-to-bins-tsv")
def gplascc_to_bins_tsv(
    gplascc_tab: Annotated[
        Path,
        typer.Argument(help="Path to the GplasCC result tab file"),
    ],
    bins_tsv: Annotated[Path, typer.Argument(help="Path to the bins.tsv file")],
    keep_unbinned: Annotated[bool, typer.Option("--keep-unbinned")] = False,
) -> None:
    """Convert gplascc result to PlasBin-flow bins.tsv file."""
    bins_contigs_mults: dict[str, list[pbf_comp_items.ContigMult]] = {}
    with gplascc_tab.open() as gplascc_fin:
        gplascc_reader = csv.reader(gplascc_fin, delimiter="\t")
        iter_gplascc = iter(gplascc_reader)
        next(iter_gplascc)  # skip header
        for line in iter_gplascc:
            ctg_name = line[3]
            true_ctg_name = ctg_name.split("_")[0][1:]
            bin_id = line[7]
            if bin_id != "Unbinned" or keep_unbinned:
                if bin_id not in bins_contigs_mults:
                    bins_contigs_mults[bin_id] = []
                bins_contigs_mults[bin_id].append(
                    pbf_comp_items.ContigMult(true_ctg_name, 1),
                )

    with pbf_comp_io.BinsWriter.open(bins_tsv) as bins_writer:
        for bin_id, contigs_mults in bins_contigs_mults.items():
            bins_writer.write_bin_line(
                pbf_comp_items.PBFBinInfo(
                    bin_id,
                    0,
                    (0.0, 1.0),
                    contigs_mults,
                ),
            )


@APP.command("platon-to-pbf-seeds")
def platon_to_pbf(
    classification_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the TSV file"),
    ],
    pbf_seeds_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the PBF seeds TSV file"),
    ],
) -> None:
    """Convert a Platon classification into a PlasBin-flow seed file."""
    with (
        classification_tsv.open() as f_in,
        pbf_comp_io.SeedWriter.open(pbf_seeds_tsv) as pbf_writer,
    ):
        fin_reader = csv.reader(f_in, delimiter="\t")
        iter_f_in = iter(fin_reader)
        next(iter_f_in)  # skip header
        for line in iter_f_in:
            contig_name = line[0]
            pbf_writer.write_sequence(contig_name)


@APP.command()
def gt_tsv(
    ground_truth: Annotated[Path, typer.Argument(help="Path to ground truth")],
    output_file: Annotated[
        Path | None,
        typer.Option("--outfile", "-f", help="Path to the TSV output file"),
    ] = None,
) -> None:
    """Convert the ground truth file to a TSV file.

    Each line in the TSV file corresponds to one plasmid:

        plasmid_id    contig_id,contig_id,...

    """
    with ground_truth.open() as gt_in:
        # plasmid_id, contig_id, contig_length
        gt_plasmid_ctgs: dict[str, list[int]] = {}
        csv_reader = csv.reader(gt_in, delimiter="\t")
        next(csv_reader)
        for plasmid_id, contig_id, _ in csv_reader:
            if plasmid_id not in gt_plasmid_ctgs:
                gt_plasmid_ctgs[plasmid_id] = []
            gt_plasmid_ctgs[plasmid_id].append(int(contig_id))

    for gt in gt_plasmid_ctgs.values():
        gt.sort()

    if output_file is None:
        for gt_bin_id, gt_bin_ctgs in gt_plasmid_ctgs.items():
            rich.print(f"{gt_bin_id}\t{','.join(map(str, gt_bin_ctgs))}")
    else:
        with output_file.open("w") as f_out:
            for gt_bin_id, gt_bin_ctgs in gt_plasmid_ctgs.items():
                f_out.write(f"{gt_bin_id}\t{','.join(map(str, gt_bin_ctgs))}\n")


@APP.command(name="gt-ctg")
def ground_truth_contigs(
    ground_truth: Annotated[Path, typer.Argument(help="Path to ground truth")],
    output_file: Annotated[Path, typer.Argument(help="Path to the output file")],
) -> None:
    """Write all the ground truth plasmid contigs in a file.

    One line coresponds to one contig identifier.
    """
    # REFACTOR use Reader
    gt_contigs = set()
    with ground_truth.open() as gt_in:
        # plasmid_id, contig_id, contig_length
        csv_reader = csv.reader(gt_in, delimiter="\t")
        next(csv_reader)
        for _, contig_id, _ in csv_reader:
            gt_contigs.add(contig_id)

    with output_file.open("w") as f_out:
        for ctg in sorted(gt_contigs):
            f_out.write(f"{ctg}\n")


@APP.command(name="pg-ctg")
def pangebin_contigs(
    bins_tsv: Annotated[Path, typer.Argument(help="Path to bins.tsv file")],
    output_file: Annotated[Path, typer.Argument(help="Path to the output file")],
) -> None:
    """Write all the pangebin plasmid contigs in a file.

    One line coresponds to one contig identifier.
    """
    pg_ctgs = set()
    with pbf_comp_io.BinsReader.open(bins_tsv) as bins_reader:
        for pg_bin in bins_reader:
            for ctg_mult in pg_bin.contigs_mults():
                pg_ctgs.add(ctg_mult.identifier())

    with output_file.open("w") as f_out:
        for ctg in sorted(pg_ctgs):
            f_out.write(f"{ctg}\n")


@APP.command(name="gt-diff-pg-ctg")
def ground_truth_diff_pangebin_contigs(
    gfa_graph: Annotated[Path, typer.Argument(help="Path to the GFA graph")],
    ground_truth: Annotated[Path, typer.Argument(help="Path to ground truth")],
    bins_tsv: Annotated[Path, typer.Argument(help="Path to bins.tsv file")],
    output_file: Annotated[Path, typer.Argument(help="Path to the output TSV file")],
) -> None:
    """Write in a TSV file the differences between ground truth and pangebin contigs."""
    all_ctgs = {segment_line.name for segment_line in gfa_iter.segment_lines(gfa_graph)}
    # REFACTOR use Reader
    gt_contigs = set()
    with ground_truth.open() as gt_in:
        # plasmid_id, contig_id, contig_length
        csv_reader = csv.reader(gt_in, delimiter="\t")
        next(csv_reader)
        for _, contig_id, _ in csv_reader:
            gt_contigs.add(contig_id)

    no_gt_ctgs = all_ctgs - gt_contigs

    pg_ctgs = set()
    with pbf_comp_io.BinsReader.open(bins_tsv) as bins_reader:
        for pg_bin in bins_reader:
            for ctg_mult in pg_bin.contigs_mults():
                pg_ctgs.add(ctg_mult.identifier())

    no_pg_ctgs = all_ctgs - pg_ctgs

    with output_file.open("w") as f_out:
        csv_writer = csv.writer(f_out, delimiter="\t")
        csv_writer.writerow(["Type", "Contigs"])
        csv_writer.writerow(
            ["True_positive", ",".join(ctg for ctg in sorted(pg_ctgs & gt_contigs))],
        )
        csv_writer.writerow(
            ["False_positive", ",".join(ctg for ctg in sorted(pg_ctgs - gt_contigs))],
        )
        csv_writer.writerow(
            ["True_negative", ",".join(ctg for ctg in sorted(no_pg_ctgs & no_gt_ctgs))],
        )
        csv_writer.writerow(
            [
                "False_negative",
                ",".join(ctg for ctg in sorted(no_pg_ctgs - no_gt_ctgs)),
            ],
        )


@APP.command(name="bandage-bins")
def bandage_bins(
    pbf_bins_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the pbf_bins.tsv file"),
    ],
    bandage_bins_csv: Annotated[
        Path,
        typer.Argument(help="Path to the bandage_bins.tsv file"),
    ],
) -> None:
    """Convert pbf_bins.tsv to bandage_bins.tsv."""
    with (
        pbf_comp_io.BinsReader.open(pbf_bins_tsv) as pbf_reader,
        bandage_bins_csv.open(
            "w",
        ) as f_out,
    ):
        for bin_info in pbf_reader:
            f_out.write(f"{bin_info.identifier()}\t")
            f_out.write(
                ",".join(
                    (str(ctg_mult.identifier()))
                    for ctg_mult in bin_info.contigs_mults()
                )
                + "\n",
            )


@APP.command(name="bandage-seeds")
def bandage_seeds(
    pbf_seeds_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the pbf_seeds.tsv file"),
    ],
    bandage_seeds_csv: Annotated[
        Path,
        typer.Argument(help="Path to the bandage_seeds.csv file"),
    ],
) -> None:
    """Convert pbf_seeds.tsv to bandage_seeds.csv."""
    with pbf_seeds_tsv.open() as f_in, bandage_seeds_csv.open("w") as f_out:
        seeds = [line.strip() for line in f_in]
        f_out.write(",".join(seeds) + "\n")


@APP.command(name="bandage-plasmidness")
def bandage_plasmidness(
    pbf_plasmidness_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the pbf_plasmidness.tsv file"),
    ],
    bandage_plasmidness_csv: Annotated[
        Path,
        typer.Argument(help="Path to the bandage_plasmidness.csv file"),
    ],
) -> None:
    """Convert pbf_plasmidness.tsv to bandage_plasmidness.csv."""
    with pbf_plasmidness_tsv.open() as f_in, bandage_plasmidness_csv.open("w") as f_out:
        contig_id_plm = [line.split() for line in f_in]
        f_out.write("contig_id,plasmidness\n")
        for ctg_id_plm in contig_id_plm:
            f_out.write(",".join(ctg_id_plm) + "\n")


@APP.command(name="pg-cov-remain")
def pangebin_coverage_remain(
    smp_dir: Annotated[
        Path,
        typer.Argument(help="Path to the result sample directory"),
    ],
    gfa_graph: Annotated[Path, typer.Argument(help="Path to the GFA graph")],
    cov_usage_dir: Annotated[
        Path,
        typer.Argument(help="Path to the coverage usage directory"),
    ],
) -> None:
    """Write in CSV the coverage usage by a solution."""
    # For each connected component
    # CtgID BinID ... ALL    REMAIN
    # uid   0.3       0.98   0.02
    root_res_reader = hmf_res.RootReader.from_output_dir(smp_dir)

    d_ctg_cov = dict(gfa_asm_ops.contig_coverages(gfa_io.from_file(gfa_graph)))

    for cc_idx, cc_res_reader in enumerate(
        root_res_reader.connected_component_readers(),
    ):
        header = ["contig_id"]
        d_ctg_cov_usage: dict[str, list[float]] = {ctg_id: [] for ctg_id in d_ctg_cov}

        for bin_idx, bin_res_reader in enumerate(cc_res_reader.all_bins()):
            header.append(f"b_{bin_idx}")
            norm_cov_coeff = (
                bin_res_reader.results_reader().bin_stats().normalizing_coverage()
            )
            for ctg_norm_cov in bin_res_reader.results_reader().iter_seq_normcov():
                if ctg_norm_cov.identifier() not in d_ctg_cov_usage:
                    d_ctg_cov_usage[ctg_norm_cov.identifier()] = []

                d_ctg_cov_usage[ctg_norm_cov.identifier()].append(
                    ctg_norm_cov.normalized_coverage() * norm_cov_coeff,
                )

        number_of_bins = sum(1 for _ in cc_res_reader.all_bins())
        if number_of_bins:
            for cov_usage in d_ctg_cov_usage.values():
                if not cov_usage:
                    cov_usage.extend([0.0] * number_of_bins)

            header.append("ALL")
            for cov_usage in d_ctg_cov_usage.values():
                cov_usage.append(sum(cov_usage))

            header.append("REMAIN")
            for ctg_id, cov_usage in d_ctg_cov_usage.items():
                cum_cov = cov_usage[-1]
                cov_usage.append(d_ctg_cov[ctg_id] - cum_cov)

            cc_cov_usage_csv = cov_usage_dir / f"cov_usage_cc_{cc_idx}.csv"

            with cc_cov_usage_csv.open("w") as f_out:
                f_out.write(",".join(header) + "\n")
                for ctg_id, cov_usages in d_ctg_cov_usage.items():
                    f_out.write(
                        f"{ctg_id},"
                        + ",".join(map(str, (round(cu, 2) for cu in cov_usages)))
                        + "\n",
                    )


if __name__ == "__main__":
    APP()
