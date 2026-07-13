"""Merge PlasEval evaluations."""

import csv
import warnings
from enum import IntEnum, StrEnum
from pathlib import Path
from typing import Annotated, Self

import pandas as pd
import typer
from rich import print as rprint

APP = typer.Typer(
    name="merge-plaseval-evaluations",
    help="Merge PlasEval evaluations.",
)


class SamplesHeader(IntEnum):
    """Samples header."""

    SPECIES_ID = 0
    SAMPLE_ID = 1


def fmt_sample_uid(row: list[str]) -> str:
    """Get the sample UID."""
    species_id = row[SamplesHeader.SPECIES_ID.value]
    sample_id = row[SamplesHeader.SAMPLE_ID.value]
    return f"{species_id}-{sample_id}"


class MethodCodes(StrEnum):
    """Method codes."""

    MOB = "mob"
    PBF_RFPL = "pbf_rfpl"
    PBF_RFPL_FILT = "pbf_rfpl_filt"
    PBHMF_RFPL = "pbhmf_rfpl"
    PBHMF_RFPL_FILT = "pbhmf_rfpl_filt"
    GPCC_RFPL = "gpcc_rfpl"


class PlasEvalCmds(StrEnum):
    """PlasEval commands."""

    COMP = "comp"
    EVAL = "eval"


class PlasEvalFSManager:
    """PlasEval file system manager."""

    def __init__(self, output_dir: Path) -> None:
        self._output_dir: Path = output_dir

    def output_dir(self) -> Path:
        """Get the output directory."""
        return self._output_dir

    def _filename(self, sample_uid: str, method_code: MethodCodes, ext: str) -> str:
        return f"{sample_uid}_{method_code.value}_gt.{ext}"

    def out_file(self, sample_uid: str, method_code: MethodCodes) -> Path:
        """Get the output file."""
        return self._output_dir / self._filename(sample_uid, method_code, "out")

    def log_file(self, sample_uid: str, method_code: MethodCodes) -> Path:
        """Get the log file."""
        return self._output_dir / self._filename(sample_uid, method_code, "log")


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

    SAMPLES_TSV = typer.Argument(help="Path to samples TSV")
    EVAL_DIR = typer.Argument(help="Path to evaluation directory")
    OUTPUT_DIR = typer.Argument(help="Path to output directory")


class Opts:
    """Typer options."""

    METHOD_CODE = typer.Option("-m", help="Method code")


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
    samples_tsv: Annotated[Path, Args.SAMPLES_TSV],
    evals_dir: Annotated[Path, Args.EVAL_DIR],
    output_dir: Annotated[Path, Args.OUTPUT_DIR],
    method_codes: Annotated[list[MethodCodes], Opts.METHOD_CODE],
) -> None:
    """Merge PlasEval evaluations."""
    if not samples_tsv.exists():
        rprint("[red]Samples TSV not found:[/red]", samples_tsv)
        raise typer.Exit(1)

    if not evals_dir.exists():
        rprint("[red]Evaluations directory not found:[/red]", evals_dir)
        raise typer.Exit(1)

    plaseval_fs = PlasEvalFSManager(evals_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    merge_fs = MergeFsManager(output_dir, PlasEvalCmds.COMP)

    rprint("Merging Plaseval comp command evaluations...")
    with samples_tsv.open() as f, merge_fs.merge_evals_tsv().open("w") as f_out:
        smpl_rdr = csv.reader(f, delimiter="\t")
        merge_wrt = csv.writer(f_out, delimiter="\t")

        next(smpl_rdr)  # skip header
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

        d_spe_meth_pos_count: dict[str, dict[str, int]] = {}  # species: method: count
        d_spe_meth_miss_count: dict[str, dict[str, int]] = {}  # species: method: count
        for row in smpl_rdr:
            species = row[SamplesHeader.SPECIES_ID.value]
            sample_uid = fmt_sample_uid(row)

            if species not in d_spe_meth_pos_count:
                d_spe_meth_pos_count[species] = {
                    method_code.value: 0 for method_code in method_codes
                }
            if species not in d_spe_meth_miss_count:
                d_spe_meth_miss_count[species] = {
                    method_code.value: 0 for method_code in method_codes
                }

            missing_evals = d_spe_meth_miss_count[species]
            positive_evals = d_spe_meth_pos_count[species]

            for method_code in method_codes:
                out_file = plaseval_fs.out_file(
                    sample_uid,
                    method_code,
                )
                if not out_file.exists() or out_file.stat().st_size == 0:
                    missing_evals[method_code.value] += 1
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
                    positive_evals[method_code.value] += 1

                    try:
                        plaseval_stats = CompStats.from_file(out_file)
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
                d_spe_meth_pos_count[species] = {
                    method_code.value: 0 for method_code in method_codes
                }
            if species not in d_spe_meth_miss_count:
                d_spe_meth_miss_count[species] = {
                    method_code.value: 0 for method_code in method_codes
                }

            spe_pos_counts = d_spe_meth_pos_count[species]
            spe_miss_counts = d_spe_meth_miss_count[species]

            for method_code in method_codes:
                merge_log_wrt.writerow(
                    [
                        species,
                        method_code.value,
                        spe_pos_counts[method_code.value],
                        spe_miss_counts[method_code.value],
                        spe_pos_counts[method_code.value]
                        + spe_miss_counts[method_code.value],
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
                d_spe_meth_pos_count[species][method_code.value]
                for species in all_species
            )
            miss_count = sum(
                d_spe_meth_miss_count[species][method_code.value]
                for species in all_species
            )
            merge_log_wrt.writerow(
                [
                    "all",
                    method_code.value,
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
    samples_tsv: Annotated[Path, Args.SAMPLES_TSV],
    evals_dir: Annotated[Path, Args.EVAL_DIR],
    output_dir: Annotated[Path, Args.OUTPUT_DIR],
    method_codes: Annotated[list[MethodCodes], Opts.METHOD_CODE],
) -> None:
    """Merge the PlasEval eval results."""
    if not samples_tsv.exists():
        rprint("[red]Samples TSV not found:[/red]", samples_tsv)
        raise typer.Exit(1)

    if not evals_dir.exists():
        rprint("[red]Evaluations directory not found:[/red]", evals_dir)
        raise typer.Exit(1)

    plaseval_fs = PlasEvalFSManager(evals_dir)
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
    with samples_tsv.open() as f:
        smpl_rdr = csv.reader(f, delimiter="\t", quotechar='"')
        next(smpl_rdr)  # skip header
        for row in smpl_rdr:
            species = row[SamplesHeader.SPECIES_ID.value]
            sample_uid = fmt_sample_uid(row)

            for method_code in method_codes:
                eval_tsv = plaseval_fs.out_file(sample_uid, method_code)
                if not eval_tsv.exists() or eval_tsv.stat().st_size == 0:
                    # Add a row with Nan values
                    with warnings.catch_warnings():
                        warnings.simplefilter(action="ignore", category=FutureWarning)
                        merge_eval_df.loc[len(merge_eval_df)] = [
                            species,
                            sample_uid,
                            method_code.value,
                            None,
                            None,
                            None,
                            None,
                            None,
                            None,
                        ]
                else:
                    eval_stats = pd.read_csv(eval_tsv, sep="\t", header=0)
                    # Get rows where "Level" column == "Overall"
                    overall_rows: pd.DataFrame = eval_stats[
                        eval_stats["Level"] == "Overall"
                    ]

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
                                f" for {sample_uid} {method_code.value}"
                                f" ({eval_tsv})."
                                "[/red]",
                            )
                            raise typer.Exit(1)
                        stats[stat] = unw_w_stats

                    merge_eval_df.loc[len(merge_eval_df)] = [
                        species,
                        sample_uid,
                        method_code.value,
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
