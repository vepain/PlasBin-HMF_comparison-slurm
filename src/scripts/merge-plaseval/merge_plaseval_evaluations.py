"""Merge PlasEval evaluations."""

import csv
import warnings
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Annotated, Self

import pandas as pd
import typer
from rich import print as rprint

APP = typer.Typer(
    name="merge-plaseval-evaluations",
    help="Merge PlasEval evaluations.",
)


class EvalsTSVHeader(StrEnum):
    """Evals TSV header."""

    SPECIES_ID = "species_id"
    SAMPLE_UID = "sample_uid"
    METHOD_CODE = "method_code"
    EVAL_FILE = "eval_file"


def get_evals_df(evals_tsv: Path) -> pd.DataFrame:
    """Get the evals dataframe."""
    return pd.read_csv(
        evals_tsv,
        sep="\t",
        dtype={
            EvalsTSVHeader.SPECIES_ID.value: str,
            EvalsTSVHeader.SAMPLE_UID.value: str,
            EvalsTSVHeader.METHOD_CODE.value: str,
            EvalsTSVHeader.EVAL_FILE.value: Path,
        },
        header=True,
    )


@dataclass(frozen=True)
class EvalsRowParser:
    """Evals row parser."""

    row: pd.Series

    def species_id(self) -> str:
        """Get the species ID."""
        return self.row[EvalsTSVHeader.SPECIES_ID.value]

    def sample_uid(self) -> str:
        """Get the sample UID."""
        return self.row[EvalsTSVHeader.SAMPLE_UID.value]

    def method_code(self) -> str:
        """Get the method code."""
        return self.row[EvalsTSVHeader.METHOD_CODE.value]

    def eval_file(self) -> Path:
        """Get the eval file."""
        return self.row[EvalsTSVHeader.EVAL_FILE.value]


class PlasEvalCmds(StrEnum):
    """PlasEval commands."""

    COMP = "comp"
    EVAL = "eval"


class MergeFsManager:
    """Merge PlasEval evaluations file system manager."""

    def __init__(self, output_dir: Path, cmd: PlasEvalCmds) -> None:
        self._output_dir: Path = output_dir
        self._cmd: PlasEvalCmds = cmd

    def output_dir(self) -> Path:
        """Get the output directory."""
        return self._output_dir

    def merge_evals_tsv(self) -> Path:
        """Get the merge evals TSV file."""
        return self._output_dir / Path(f"{self._cmd}_merge_evals.tsv")

    def log_file(self) -> Path:
        """Get the log file."""
        return self._output_dir / Path(f"{self._cmd}_merge_stats.tsv")


class Args:
    """Typer arguments."""

    EVALS_TSV = typer.Argument(
        help=(
            "Path to evaluations TSV, with columns: sample_uid method_code eval_file"
        ),
    )
    OUTPUT_DIR = typer.Argument(help="Path to output directory")


class Opts:
    """Typer options."""

    METHOD_CODE = typer.Option("-m", help="Method code")
    METHOD_EVAL = typer.Option("-e", help="Method eval")


class CompStats:
    """PlasEval comp out stats."""

    class Keys(StrEnum):
        """Keys."""

        CUTS = "Cuts"
        JOINS_COST = "Joins"
        EXTRA_CTGS = "Extra_ctgs"
        MISSING_CTGS = "Missing_ctgs"
        DISSIMILARITY = "Dissimilarity"

    @classmethod
    def from_file(cls, file_path: Path) -> Self:
        """Create from file."""
        d_stats = {}
        value_pos = {
            cls.Keys.CUTS.value: 2,
            cls.Keys.JOINS_COST.value: 2,
            cls.Keys.EXTRA_CTGS.value: 2,
            cls.Keys.MISSING_CTGS.value: 2,
            cls.Keys.DISSIMILARITY.value: 2,
        }
        with file_path.open() as f:
            reader = csv.reader(f, delimiter="\t")
            for row in reader:
                if row[0] in value_pos:
                    d_stats[row[0]] = row[value_pos[row[0]]]

        for key in cls.Keys:
            if key.value not in d_stats:
                _err_msg = f"Key {key.value} not found in {file_path}"
                raise ValueError(_err_msg)

        return cls(
            cuts=float(d_stats[cls.Keys.CUTS]),
            joins=float(d_stats[cls.Keys.JOINS_COST]),
            extra=float(d_stats[cls.Keys.EXTRA_CTGS]),
            missing=float(d_stats[cls.Keys.MISSING_CTGS]),
            dissimilarity=float(d_stats[cls.Keys.DISSIMILARITY]),
        )

    def __init__(
        self,
        cuts: float,
        joins: float,
        extra: float,
        missing: float,
        dissimilarity: float,
    ) -> None:
        self._cuts = cuts
        self._joins = joins
        self._extra = extra
        self._missing = missing
        self._dissimilarity = dissimilarity

    def cuts(self) -> float:
        """Get the cuts cost."""
        return self._cuts

    def joins(self) -> float:
        """Get the joins cost."""
        return self._joins

    def extra(self) -> float:
        """Get the unique left contigs."""
        return self._extra

    def missing(self) -> float:
        """Get the unique right contigs."""
        return self._missing

    def dissimilarity(self) -> float:
        """Get the dissimilarity score."""
        return self._dissimilarity


class CompMergeHeader(StrEnum):
    """Merge header."""

    SPECIES_ID = "species_id"
    SAMPLE_UID = "sample_uid"
    METHOD_CODE = "method_code"
    CUTS = CompStats.Keys.CUTS
    JOINS = CompStats.Keys.JOINS_COST
    EXTRA_CTGS = CompStats.Keys.EXTRA_CTGS
    MISSING_CTGS = CompStats.Keys.MISSING_CTGS
    DISSIMILARITY = CompStats.Keys.DISSIMILARITY


@APP.command("comp")
def comp_results(
    evals_tsv: Annotated[Path, Args.EVALS_TSV],
    output_dir: Annotated[Path, Args.OUTPUT_DIR],
) -> None:
    """Merge PlasEval evaluations."""
    if not evals_tsv.exists():
        rprint("[red]Evaluations TSV not found:[/red]", evals_tsv)
        raise typer.Exit(1)

    df_evals = get_evals_df(evals_tsv)

    output_dir.mkdir(parents=True, exist_ok=True)
    merge_fs = MergeFsManager(output_dir, PlasEvalCmds.COMP)

    rprint("Merging Plaseval comp command evaluations...")
    with merge_fs.merge_evals_tsv().open("w") as f_out:
        merge_wrt = csv.writer(f_out, delimiter="\t")
        merge_wrt.writerow(
            [
                CompMergeHeader.SPECIES_ID.value,
                CompMergeHeader.SAMPLE_UID.value,
                CompMergeHeader.METHOD_CODE.value,
                CompMergeHeader.CUTS.value,
                CompMergeHeader.JOINS.value,
                CompMergeHeader.EXTRA_CTGS.value,
                CompMergeHeader.MISSING_CTGS.value,
                CompMergeHeader.DISSIMILARITY.value,
            ],
        )

        d_spe_meth_pos_count: dict[
            str,
            dict[str, int],
        ] = {}  # species: method: count
        d_spe_meth_miss_count: dict[
            str,
            dict[str, int],
        ] = {}  # species: method: count
        for _, row in df_evals.iterrows():
            row_parser = EvalsRowParser(row)

            species = row_parser.species_id()
            sample_uid = row_parser.sample_uid()
            method_code = row_parser.method_code()
            method_eval = row_parser.eval_file()

            if species not in d_spe_meth_pos_count:
                d_spe_meth_pos_count[species] = {}
            if species not in d_spe_meth_miss_count:
                d_spe_meth_miss_count[species] = {}

            if method_code not in d_spe_meth_pos_count[species]:
                d_spe_meth_pos_count[species][method_code] = 0
            if method_code not in d_spe_meth_miss_count[species]:
                d_spe_meth_miss_count[species][method_code] = 0

            missing_evals = d_spe_meth_miss_count[species]
            positive_evals = d_spe_meth_pos_count[species]

            if not method_eval.exists() or method_eval.stat().st_size == 0:
                missing_evals[method_code] += 1
                merge_wrt.writerow(
                    [
                        species,
                        sample_uid,
                        method_code,
                        None,
                        None,
                        None,
                        None,
                        None,
                    ],
                )

            else:
                positive_evals[method_code] += 1

                try:
                    plaseval_stats = CompStats.from_file(method_eval)
                except ValueError as e:
                    rprint("[red]Error:[/red]", e)
                    raise typer.Exit(1) from e
                merge_wrt.writerow(
                    [
                        species,
                        sample_uid,
                        method_code,
                        plaseval_stats.cuts(),
                        plaseval_stats.joins(),
                        plaseval_stats.extra(),
                        plaseval_stats.missing(),
                        plaseval_stats.dissimilarity(),
                    ],
                )

    method_codes = list(df_evals[EvalsTSVHeader.METHOD_CODE.value].unique())

    rprint("Writing log...")
    with merge_fs.log_file().open("w") as f:
        merge_log_wrt = csv.writer(f, delimiter="\t")
        merge_log_wrt.writerow(
            ["Species", "Method_code", "Positive_evals", "Missing_evals", "Total"],
        )

        all_species = set(d_spe_meth_pos_count.keys()).union(
            d_spe_meth_miss_count.keys(),
        )
        for species in all_species:
            if species not in d_spe_meth_pos_count:
                d_spe_meth_pos_count[species] = dict.fromkeys(method_codes, 0)
            if species not in d_spe_meth_miss_count:
                d_spe_meth_miss_count[species] = dict.fromkeys(method_codes, 0)

            spe_pos_counts = d_spe_meth_pos_count[species]
            spe_miss_counts = d_spe_meth_miss_count[species]

            for method_code in method_codes:
                merge_log_wrt.writerow(
                    [
                        species,
                        method_code,
                        spe_pos_counts[method_code],
                        spe_miss_counts[method_code],
                        spe_pos_counts[method_code] + spe_miss_counts[method_code],
                    ],
                )
            merge_log_wrt.writerow(
                [
                    species,
                    "all",
                    sum(spe_pos_counts.values()),
                    sum(spe_miss_counts.values()),
                    sum(spe_pos_counts.values()) + sum(spe_miss_counts.values()),
                ],
            )
        for method_code in method_codes:
            pos_count = sum(
                d_spe_meth_pos_count[species][method_code] for species in all_species
            )
            miss_count = sum(
                d_spe_meth_miss_count[species][method_code] for species in all_species
            )
            merge_log_wrt.writerow(
                [
                    "all",
                    method_code,
                    pos_count,
                    miss_count,
                    pos_count + miss_count,
                ],
            )
        total_pos = sum(
            sum(d_spe_meth_pos_count[species].values()) for species in all_species
        )
        total_miss = sum(
            sum(d_spe_meth_miss_count[species].values()) for species in all_species
        )
        merge_log_wrt.writerow(
            [
                "all",
                "all",
                total_pos,
                total_miss,
                total_pos + total_miss,
            ],
        )

    rprint("[green]Done.[/green]")
    rprint("[green]Output directory:[/green]", output_dir)
    rprint("[green]Merge evals TSV:[/green]", merge_fs.merge_evals_tsv())
    rprint("[green]Log file:[/green]", merge_fs.log_file())


class EvalStats(StrEnum):
    """Eval stats."""

    PRECISION = "Precision"
    RECALL = "Recall"
    F1 = "F1"


class EvalMergeHeader(StrEnum):
    """Merge header."""

    SPECIES_ID = "species_id"
    SAMPLE_UID = "sample_uid"
    METHOD_CODE = "method_code"
    UNW_PRECISION = "unw_precision"
    UNW_RECALL = "unw_recall"
    UNW_F1 = "unw_f1"
    W_PRECISION = "w_precision"
    W_RECALL = "w_recall"
    W_F1 = "w_f1"


@APP.command(name="eval")
def eval_results(
    evals_tsv: Annotated[Path, Args.EVALS_TSV],
    output_dir: Annotated[Path, Args.OUTPUT_DIR],
) -> None:
    """Merge the PlasEval eval results."""
    if not evals_tsv.exists():
        rprint("[red]Evaluations TSV not found:[/red]", evals_tsv)
        raise typer.Exit(1)

    df_evals = get_evals_df(evals_tsv)

    output_dir.mkdir(parents=True, exist_ok=True)
    merge_fs = MergeFsManager(output_dir, PlasEvalCmds.EVAL)

    # Create a dataframe with header EvalHeader

    merge_eval_df = pd.DataFrame(
        columns=[
            EvalMergeHeader.SPECIES_ID.value,
            EvalMergeHeader.SAMPLE_UID.value,
            EvalMergeHeader.METHOD_CODE.value,
            EvalMergeHeader.UNW_PRECISION.value,
            EvalMergeHeader.UNW_RECALL.value,
            EvalMergeHeader.UNW_F1.value,
            EvalMergeHeader.W_PRECISION.value,
            EvalMergeHeader.W_RECALL.value,
            EvalMergeHeader.W_F1.value,
        ],
    )

    rprint("Merging Plaseval eval command evaluations...")
    for _, row in df_evals.iterrows():
        row_parser = EvalsRowParser(row)

        species = row_parser.species_id()
        sample_uid = row_parser.sample_uid()
        method_code = row_parser.method_code()
        method_eval = row_parser.eval_file()

        if not method_eval.exists() or method_eval.stat().st_size == 0:
            # Add a row with Nan values
            with warnings.catch_warnings():
                warnings.simplefilter(action="ignore", category=FutureWarning)
                merge_eval_df.loc[len(merge_eval_df)] = [
                    species,
                    sample_uid,
                    method_code,
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                ]
        else:
            eval_stats = pd.read_csv(method_eval, sep="\t", header=0)
            # Get rows where "Level" column == "Overall"
            overall_rows: pd.DataFrame = eval_stats[eval_stats["Level"] == "Overall"]

            def get_stat(
                rows: pd.DataFrame,
                stat: EvalStats,
            ) -> tuple[float, float] | None:
                """Return unweighted and weighted stats."""
                stat_row: pd.DataFrame = rows[rows["Statistic"] == stat.value]
                if len(stat_row) != 1:
                    rprint(
                        "[red]Stat parse error, len != 1:[/red]",
                        stat.value,
                    )
                    rprint(stat_row)
                    return None

                row = stat_row.iloc[0]
                return row["Unwtd_Stat"], row["Wtd_Stat"]

            stats: dict[EvalStats, tuple[float, float]] = {
                EvalStats.PRECISION: (0, 0),
                EvalStats.RECALL: (0, 0),
                EvalStats.F1: (0, 0),
            }
            for stat in stats:
                unw_w_stats = get_stat(overall_rows, stat)
                if unw_w_stats is None:
                    rprint(
                        "[red]"
                        f"Stat not found: {stat.value}"
                        f" for {sample_uid} {method_code}"
                        f" ({method_eval})."
                        "[/red]",
                    )
                    raise typer.Exit(1)
                stats[stat] = unw_w_stats

            merge_eval_df.loc[len(merge_eval_df)] = [
                species,
                sample_uid,
                method_code,
                stats[EvalStats.PRECISION][0],
                stats[EvalStats.RECALL][0],
                stats[EvalStats.F1][0],
                stats[EvalStats.PRECISION][1],
                stats[EvalStats.RECALL][1],
                stats[EvalStats.F1][1],
            ]

    merge_eval_df.to_csv(merge_fs.merge_evals_tsv(), sep="\t", index=False)
    rprint("[green]Evaluations merged:[/green]", merge_fs.merge_evals_tsv())


if __name__ == "__main__":
    APP()
