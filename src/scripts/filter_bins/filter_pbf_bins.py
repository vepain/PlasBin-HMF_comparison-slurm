"""Filter binning results."""
# Due to typer usage:

from __future__ import annotations

import csv
from contextlib import contextmanager
from enum import StrEnum
from pathlib import Path
from typing import TYPE_CHECKING, Annotated

import typer

if TYPE_CHECKING:
    import _csv
    from collections.abc import Generator, Iterable, Iterator
    from pathlib import Path


# ============================================================================ #
#                                     ITEMS                                    #
# ============================================================================ #
class ContigMult:
    """PlasBin-flow contig multiplicity."""

    def __init__(self, contig_id: str, contig_mult: float) -> None:
        self.__contig_id = contig_id
        self.__contig_mult = contig_mult

    def identifier(self) -> str:
        """Contig ID."""
        return self.__contig_id

    def multiplicity(self) -> float:
        """Contig multiplicity."""
        return self.__contig_mult


class PBFBinInfo:
    """PlasBin-flow bin info."""

    def __init__(
        self,
        bin_id: str,
        flow: float,
        gc_interval: tuple[float, float],
        contigs_mults: Iterable[ContigMult],
    ) -> None:
        self.__bin_id = bin_id
        self.__flow = flow
        self.__gc_interval = gc_interval
        self.__contigs_mults = list(contigs_mults)

    def identifier(self) -> str:
        """Bin ID."""
        return self.__bin_id

    def flow(self) -> float:
        """Flow."""
        return self.__flow

    def gc_interval(self) -> tuple[float, float]:
        """GC interval."""
        return self.__gc_interval

    def contigs_mults(self) -> Iterable[ContigMult]:
        """Contigs multiplicity."""
        return self.__contigs_mults


# ============================================================================ #
#                                      IO                                      #
# ============================================================================ #
class PlmWriter:
    """PlasBin-flow plasmidness scores TSV writer."""

    @classmethod
    @contextmanager
    def open(
        cls,
        file: Path,
    ) -> Generator[PlmWriter, None, None]:
        """Open TSV file for writing."""
        with file.open("w") as f_out:
            writer = PlmWriter(csv.writer(f_out, delimiter="\t"))
            yield writer

    def __init__(self, csv_writer: _csv.Writer) -> None:
        """Initialize object."""
        self.__csv_writer = csv_writer

    def write_sequence_plasmidness(self, sequence_id: str, plasmidness: float) -> None:
        """Write sequence probability scores."""
        self.__csv_writer.writerow([sequence_id, plasmidness])


class PlmReader:
    """PlasBin-flow plasmidness scores TSV reader."""

    @classmethod
    @contextmanager
    def open(cls, file: Path) -> Generator[PlmReader, None, None]:
        """Open TSV file for reading."""
        with file.open() as f_in:
            reader = PlmReader(csv.reader(f_in, delimiter="\t"))
            yield reader

    def __init__(self, csv_reader: _csv.Reader) -> None:
        """Initialize object."""
        self.__csv_reader = csv_reader

    def __iter__(self) -> Iterator[tuple[str, float]]:
        """Iterate sequence probability scores."""
        return ((row[0], float(row[1])) for row in self.__csv_reader)


class SeedWriter:
    """PlasBin-flow seed sequences TSV writer."""

    @classmethod
    @contextmanager
    def open(
        cls,
        file: Path,
    ) -> Generator[SeedWriter, None, None]:
        """Open TSV file for writing."""
        with file.open("w") as f_out:
            writer = SeedWriter(csv.writer(f_out, delimiter="\t"))
            yield writer

    def __init__(self, csv_writer: _csv.Writer) -> None:
        """Initialize object."""
        self.__csv_writer = csv_writer

    def write_sequence(self, sequence_id: str) -> None:
        """Write sequence probability scores."""
        self.__csv_writer.writerow([sequence_id])


class SeedReader:
    """PlasBin-flow seed sequences TSV reader."""

    @classmethod
    @contextmanager
    def open(cls, file: Path) -> Generator[SeedReader, None, None]:
        """Open TSV file for reading."""
        with file.open() as f_in:
            reader = SeedReader(csv.reader(f_in, delimiter="\t"))
            yield reader

    def __init__(self, csv_reader: _csv.Reader) -> None:
        """Initialize object."""
        self.__csv_reader = csv_reader

    def __iter__(self) -> Iterator[str]:
        """Iterate sequence probability scores."""
        return (row[0] for row in self.__csv_reader)


class BinsHeader(StrEnum):
    """PlasBin-flow bins header."""

    PLASMID_ID = "#Pls_ID"
    FLOW = "Flow"
    GC_INTERVAL = "GC_bin"
    CONTIGS = "Contigs"


class IntervalFormatter:
    """PlasBin-flow interval formatter."""

    SEP = "-"

    @classmethod
    def to_str(cls, interval: tuple[float, float]) -> str:
        """Format interval."""
        return f"{interval[0]}{cls.SEP}{interval[1]}"

    @classmethod
    def from_str(cls, interval_str: str) -> tuple[float, float]:
        """Parse interval."""
        l_split = interval_str.split(cls.SEP)
        return (float(l_split[0]), float(l_split[1]))


class ContigMultFormatter:
    """PlasBin-flow contig multiplier formatter."""

    _SEP = ":"

    @classmethod
    def to_str(cls, contig_mult: ContigMult) -> str:
        """Format contig multiplier."""
        return f"{contig_mult.identifier()}{cls._SEP}{contig_mult.multiplicity():.2f}"

    @classmethod
    def from_str(cls, contig_mult_str: str) -> ContigMult:
        """Parse contig multiplier."""
        l_split = contig_mult_str.split(cls._SEP)
        return ContigMult(l_split[0], float(l_split[1]))


class BinsWriter:
    """PlasBin-flow bins TSV writer."""

    @classmethod
    @contextmanager
    def open(
        cls,
        file: Path,
    ) -> Generator[BinsWriter, None, None]:
        """Open TSV file for writing."""
        with file.open("w") as f_out:
            writer = BinsWriter(csv.writer(f_out, delimiter="\t"))
            writer.__write_header()
            yield writer

    def __init__(self, csv_writer: _csv.Writer) -> None:
        """Initialize object."""
        self.__csv_writer = csv_writer

    def __write_header(self) -> None:
        """Write header."""
        self.__csv_writer.writerow(
            [
                BinsHeader.PLASMID_ID,
                BinsHeader.FLOW,
                BinsHeader.GC_INTERVAL,
                BinsHeader.CONTIGS,
            ],
        )

    def write_bin_line(
        self,
        bin_info: PBFBinInfo,
    ) -> None:
        """Write bin line."""
        self.__csv_writer.writerow(
            [
                bin_info.identifier(),
                bin_info.flow(),
                IntervalFormatter.to_str(bin_info.gc_interval()),
                ",".join(
                    ContigMultFormatter.to_str(contig_mult)
                    for contig_mult in bin_info.contigs_mults()
                ),
            ],
        )


class BinsReader:
    """PlasBin-flow bin info TSV reader."""

    @classmethod
    @contextmanager
    def open(cls, file: Path) -> Generator[BinsReader, None, None]:
        """Open TSV file for reading."""
        with file.open() as f_in:
            reader = BinsReader(csv.reader(f_in, delimiter="\t"))
            next(reader.__csv_reader)  # skip header
            yield reader

    def __init__(self, csv_reader: _csv.Reader) -> None:
        """Initialize object."""
        self.__csv_reader = csv_reader

    def __iter__(
        self,
    ) -> Iterator[PBFBinInfo]:
        """Iterate sequence probability scores."""
        return (
            PBFBinInfo(
                row[0],
                float(row[1]),
                IntervalFormatter.from_str(row[2]),
                (
                    ContigMultFormatter.from_str(ctg_id_mult)
                    for ctg_id_mult in row[3].split(",")
                ),
            )
            for row in self.__csv_reader
        )


# ============================================================================ #
#                                  APPLICATION                                 #
# ============================================================================ #
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
    with PlmReader.open(pbf_plasmidness_tsv) as plm_in:
        contigs_plm = dict(plm_in)

    with SeedReader.open(pbf_seeds_tsv) as seed_in:
        seeds = set(seed_in)

    with (
        BinsReader.open(bins_tsv) as bins_reader,
        BinsWriter.open(
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
                    PBFBinInfo(
                        bin_infos.identifier(),
                        bin_infos.flow(),
                        bin_infos.gc_interval(),
                        contigs_mult,
                    ),
                )


if __name__ == "__main__":
    APP()
