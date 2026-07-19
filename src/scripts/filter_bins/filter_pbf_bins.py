"""Filter binning results."""


# Due to typer usage:
# ruff: noqa: TC001, TC003, UP007, FBT001, FBT002, PLR0913

from __future__ import annotations

from pathlib import Path
from typing import Annotated

import pangebin.pbf_comp.input_output as pbf_comp_io
import pangebin.pbf_comp.items as pbf_comp_items
import typer

APP = typer.Typer(
    name="format",
    help="Format some files.",
)


@APP.command(name="dump")
def dump() -> None:
    """Dump some data."""


@APP.command(name="rm-low-plm")
def remove_low_plasmidness(
    bins_tsv: Annotated[Path, typer.Argument(help="Path to bins.tsv file")],
    pbf_plasmidness_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the PBF plasmidness TSV file"),
    ],
    pbf_seeds_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the PBF seeds TSV file"),
    ],
    filtered_bins_tsv: Annotated[
        Path,
        typer.Argument(help="Path to the filtered bins.tsv file"),
    ],
    plasmidness_threshold: Annotated[
        float,
        typer.Option("--plm-thr", "-p", help="Plasmidness threshold"),
    ] = 0.5,
) -> None:
    """Write in a TSV file the differences between ground truth and pangebin contigs."""
    with pbf_comp_io.PlmReader.open(pbf_plasmidness_tsv) as plm_in:
        contigs_plm = dict(plm_in)

    with pbf_comp_io.SeedReader.open(pbf_seeds_tsv) as seed_in:
        seeds = set(seed_in)

    with (
        pbf_comp_io.BinsReader.open(bins_tsv) as bins_reader,
        pbf_comp_io.BinsWriter.open(
            filtered_bins_tsv,
        ) as bins_writer,
    ):
        for bin_infos in bins_reader:
            contigs_mult = [
                contig_mult
                for contig_mult in bin_infos.contigs_mults()
                if contigs_plm[contig_mult.identifier()] >= plasmidness_threshold
                or contig_mult.identifier() in seeds
            ]
            if contigs_mult:
                bins_writer.write_bin_line(
                    pbf_comp_items.PBFBinInfo(
                        bin_infos.identifier(),
                        bin_infos.flow(),
                        bin_infos.gc_interval(),
                        contigs_mult,
                    ),
                )


if __name__ == "__main__":
    APP()
