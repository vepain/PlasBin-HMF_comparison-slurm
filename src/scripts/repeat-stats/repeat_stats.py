"""Repeat stats."""

from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import pandas as pd
import rich
import typer

APP = typer.Typer(
    name="repeat-stats",
    help="Repeat stats.",
)


class AllPlasEvalBinsTSVHeader(StrEnum):
    """All PlasEval bins TSV file header."""

    SAMPLE_UID = "sample_uid"
    SPECIES_ID = "species_id"
    BINS_TSV = "bins_tsv"


def get_all_plaseval_bins_df(all_plaseval_bins_tsv: Path) -> pd.DataFrame:
    """Get the evals dataframe."""
    return pd.read_csv(
        all_plaseval_bins_tsv,
        sep="\t",
        dtype={
            AllPlasEvalBinsTSVHeader.SAMPLE_UID.value: str,
            AllPlasEvalBinsTSVHeader.SPECIES_ID.value: str,
            AllPlasEvalBinsTSVHeader.BINS_TSV.value: str,
        },
    )


@dataclass(frozen=True)
class AllPlasEvalBinsRowParser:
    """AllPlasEvalBins row parser."""

    row: pd.Series

    def species_id(self) -> str:
        """Get the species ID."""
        return self.row[AllPlasEvalBinsTSVHeader.SPECIES_ID.value]

    def sample_uid(self) -> str:
        """Get the sample UID."""
        return self.row[AllPlasEvalBinsTSVHeader.SAMPLE_UID.value]

    def bins_tsv(self) -> Path:
        """Get the bins TSV."""
        return Path(self.row[AllPlasEvalBinsTSVHeader.BINS_TSV.value])


class PlasEvalBinsTSVHeader(StrEnum):
    """PlasEval bins TSV file header."""

    PLASMID = "plasmid"
    CONTIG = "contig"
    CONTIG_LEN = "contig_len"


def get_plaseval_bins_df(plaseval_bins_tsv: Path) -> pd.DataFrame:
    """Get the evals dataframe."""
    return pd.read_csv(
        plaseval_bins_tsv,
        sep="\t",
        dtype={
            PlasEvalBinsTSVHeader.PLASMID.value: str,
            PlasEvalBinsTSVHeader.CONTIG.value: str,
            PlasEvalBinsTSVHeader.CONTIG_LEN.value: int,
        },
    )


@dataclass(frozen=True)
class PlasEvalBinsRowParser:
    """AllPlasEvalBins row parser."""

    row: pd.Series

    def plasmid(self) -> str:
        """Get the plasmid."""
        return self.row[PlasEvalBinsTSVHeader.PLASMID.value]

    def contig(self) -> str:
        """Get the contig."""
        return self.row[PlasEvalBinsTSVHeader.CONTIG.value]

    def contig_len(self) -> int:
        """Get the contig length."""
        return self.row[PlasEvalBinsTSVHeader.CONTIG_LEN.value]


class RepeatStatsTSVHeader(StrEnum):
    """Repeat stats TSV file header."""

    SAMPLE_UID = "sample_uid"
    SPECIES_ID = "species_id"
    NUM_CONTIGS = "num_contigs"
    NUM_UNIQUE_CONTIGS = "num_unique_contigs"
    REPEAT_RATIO = "repeat_ratio"


@APP.command("repeat-stats")
def cli(
    all_plaseval_bins_tsv: Annotated[
        Path,
        typer.Argument(help="File containing paths to PlasEval bins TSV files"),
    ],
    out_stats_tsv: Annotated[Path, typer.Argument(help="File to write stats to")],
) -> None:
    """Repeat stats."""
    all_plaseval_bins_df = get_all_plaseval_bins_df(all_plaseval_bins_tsv)

    rows = []
    for _, row in all_plaseval_bins_df.iterrows():
        row_parser = AllPlasEvalBinsRowParser(row)
        bins_tsv = row_parser.bins_tsv()
        bins_df = get_plaseval_bins_df(bins_tsv)

        num_contigs = len(bins_df)
        num_unique_contigs = bins_df[PlasEvalBinsTSVHeader.CONTIG.value].nunique()
        repeat_ratio = num_contigs / num_unique_contigs if num_unique_contigs else None

        rows.append(
            {
                RepeatStatsTSVHeader.SAMPLE_UID.value: row_parser.sample_uid(),
                RepeatStatsTSVHeader.SPECIES_ID.value: row_parser.species_id(),
                RepeatStatsTSVHeader.NUM_CONTIGS.value: num_contigs,
                RepeatStatsTSVHeader.NUM_UNIQUE_CONTIGS.value: num_unique_contigs,
                RepeatStatsTSVHeader.REPEAT_RATIO.value: repeat_ratio,
            },
        )

    out_stats_df = pd.DataFrame(
        rows,
        columns=[
            RepeatStatsTSVHeader.SAMPLE_UID.value,
            RepeatStatsTSVHeader.SPECIES_ID.value,
            RepeatStatsTSVHeader.NUM_CONTIGS.value,
            RepeatStatsTSVHeader.NUM_UNIQUE_CONTIGS.value,
            RepeatStatsTSVHeader.REPEAT_RATIO.value,
        ],
    )
    out_stats_df.to_csv(out_stats_tsv, sep="\t", index=False)
    rich.print(f"[green]Output written to: {out_stats_tsv}[/green]")


if __name__ == "__main__":
    APP()
