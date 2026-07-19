"""PlasEval input binning results formatter."""

import csv
from collections.abc import Iterator
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import pandas as pd
import typer
from rich import print as rprint

APP = typer.Typer(
    name="format",
    help="Format binning results to PlasEval input.",
)


class Contig:
    """Contig data."""

    def __init__(self, seq: str, length: int, rd: float | None) -> None:
        self._seq = seq
        self._length = length
        self._rd = rd
        self._gc: float = (
            (seq.count("G") + seq.count("C")) / length if length > 0 else 0
        )

    def set_seq(self, seq: str) -> None:
        """Set the contig sequence."""
        self._seq = seq

    def set_len(self, length: int) -> None:
        """Set the length of the contig sequence."""
        self._length = int(length)

    def set_rd(self, rd: float) -> None:
        """Set the read depth of the contig sequence."""
        self._rd = float(rd)

    def seq(self) -> str:
        """Return the sequence of the contig."""
        return self._seq

    def len(self) -> int:
        """Return the length of the contig."""
        return self._length

    def rd(self) -> float | None:
        """Return the read depth of the contig."""
        return self._rd

    def gc(self) -> float:
        """Return the GC content of the contig."""
        return self._gc


Edge = tuple[tuple[str, str], tuple[str, str]]


class Assembly:
    """Assembly data."""

    def __init__(self, assembly_file: Path) -> None:
        """Initiate Assembly graph attributes.

        Contigs -> ctg_dict (dictionary of Contigs),
        Edges -> edge_lst (list of edges)
        """
        self.ctg_dict: dict[str, Contig] = {}
        self.edge_lst: list[Edge] = []
        self.parse_gfa(assembly_file)

    def init_ctg(self, ctg_id: str, seq: str, length: int, rd: float | None) -> None:
        """Initiate an instance of class Contig."""
        self.ctg_dict[ctg_id] = Contig(seq, length, rd)

    def add_edge(self, edge: Edge) -> None:
        """Add edge to the edge list.

        An edge is a set of a pair of extremities
        An extremity is a 2-tuple of (ctg_id, ctg_ext)
        """
        self.edge_lst.append(edge)

    def parse_gfa(self, assembly_file: Path) -> None:
        """Read and processes the assembly graph (gfa) file."""

        def parse_vertex(line: str) -> None:
            tmp = line.split("\t")
            # Contig id and sequence
            ctg_id, ctg_seq = tmp[1], tmp[2]
            # Tags
            tags_dict = {x.split(":")[0]: x.split(":")[2] for x in tmp[3:]}
            tags_keys = tags_dict.keys()
            # Reading contig length
            ctg_len = int(tags_dict["LN"]) if "LN" in tags_keys else len(ctg_seq)
            # Reading read depth
            if "dp" in tags_keys:
                ctg_rd = float(tags_dict["dp"])
            elif "KC" in tags_keys:
                ctg_rd = int(float(tags_dict["KC"])) / ctg_len
            else:
                ctg_rd = None
            # Recording values
            self.init_ctg(ctg_id, ctg_seq, ctg_len, ctg_rd)

        def parse_edge(line: str) -> None:
            [ctg1, ori1, ctg2, ori2] = line.split("\t")[1:-1]
            ext1 = "h" if ori1 == "+" else "t"
            ext2 = "t" if ori2 == "+" else "h"
            self.add_edge(((ctg1, ext1), (ctg2, ext2)))

        with assembly_file.open("r") as ag:
            for line in ag:
                if line.startswith("S"):
                    parse_vertex(line)
                elif line.startswith("L"):
                    parse_edge(line)

    def ctgs_ids(self) -> list[str]:
        """Return list of contig IDs."""
        return list(self.ctg_dict.keys())

    def contig(self, ctg_id: str) -> Contig:
        """Return Contig instance."""
        return self.ctg_dict[ctg_id]

    def edges(self) -> list[Edge]:
        """Return list of edges."""
        return self.edge_lst

    def number_of_contigs(self) -> int:
        """Return number of contigs in the graph."""
        return len(self.ctg_dict)

    def number_of_edges(self) -> int:
        """Return number of edges in the graph."""
        return len(self.edge_lst)

    def get_degree(self, ctg_id: str) -> int:
        """Return number of edges incident on a contig."""
        d = 0
        for edge in self.edge_lst:
            if edge[0][0] == ctg_id or edge[1][0] == ctg_id:
                d += 1
        return d


def format_pbf(res_file: Path, bins_out_path: Path, assembly: Assembly) -> None:
    """Format PlasBin-flow bins.

    - binning results have one plasmid bin per line,
    - plasmid bin id in first column, list of contigs in last column of a TSV file,
    - list of contigs separated by commas,
    - each contig is of the form ctg_id:mul (type str:float)
    """
    with res_file.open("r") as f_in, bins_out_path.open("w") as f_out:
        tsv_rdr = csv.reader(f_in, delimiter="\t")
        f_out.write("plasmid\tcontig\tcontig_len\n")
        next(tsv_rdr)  # skip header
        for row in tsv_rdr:
            pls_id = row[0]
            ctgs_with_mults_str = row[3].split(",")
            for ctg_with_mult_str in ctgs_with_mults_str:
                ctg_id = ctg_with_mult_str.split(":")[0]
                ctg_len = assembly.contig(ctg_id).len()
                f_out.write(
                    f"PBF_{pls_id}\t{ctg_id}\t{ctg_len}\n",
                )


def format_hy(res_file: Path, bins_out_path: Path, assembly: Assembly) -> None:
    """Format HyAsP binning result.

    - binning results have one plasmid bin per line,
    - plasmid bin id and contigs separated by semicolon,
    - list of contigs separated by commas,
    - each contig is of the form ctg_id+ or ctg_id-.
    """
    with res_file.open("r") as f_in, bins_out_path.open("w") as f_out:
        f_out.write("plasmid\tcontig\tcontig_len\n")
        for line in f_in:
            if line and line[0] != "#":
                pls, ctgs = line.split(";")[0], line.split(";")[1].split(",")
                curr_ctg_set = set()
                for ctg in ctgs:
                    ctg_id = ctg[:-1]
                    ctg_len = assembly.contig(ctg_id).len()
                    if ctg_id not in curr_ctg_set:
                        f_out.write(
                            "HY_" + pls + "\t" + ctg_id + "\t" + str(ctg_len) + "\n",
                        )
                f_out.write("\n")


def format_mob(res_file: Path, bins_out_path: Path, assembly: Assembly) -> None:
    """Format MOB-recon binning result.

    - binning results in TSV file (one contig per line),
    - only lines with molecule_type 'plasmid' relevant
    - plasmid bin id is obtained from the primary_cluster_id column
    - ctg_id is obtained from the contig_id column
    """
    ctg_df = pd.read_csv(res_file, sep="\t")
    pls_df = ctg_df[ctg_df["molecule_type"] == "plasmid"]

    with bins_out_path.open("w") as f_out:
        f_out.write("plasmid\tcontig\tcontig_len\n")
        for _, row in pls_df.iterrows():
            pls, ctg_id = row["primary_cluster_id"], str(row["contig_id"]).split(" ")[0]
            ctg_len = assembly.contig(ctg_id).len()
            f_out.write("MOB_" + pls + "\t" + ctg_id + "\t" + str(ctg_len) + "\n")


def format_gplas(res_file: Path, bins_out_path: Path, assembly: Assembly) -> None:
    """Format gplasCC binning result (without the unbinned contigs).

    - binning results in a space separated file (one contig per line),
    - ctg_id in first column, plasmid bin id in last column,
    - some contigs might be unbinned, these are treated as individual plasmids,
    """
    with res_file.open("r") as f_in, bins_out_path.open("w") as f_out:
        iter_lines: Iterator[str] = iter(f_in)

        f_out.write("plasmid\tcontig\tcontig_len\n")

        next(iter_lines)  # skip header
        for line in iter_lines:
            if line:
                ctg_id, pls = (
                    line.split("\t")[0],
                    line.split("\t")[-1].removesuffix("\n"),
                )
                if pls != "Unbinned":
                    ctg_len = assembly.contig(ctg_id).len()
                    f_out.write(
                        "GP_" + pls + "\t" + ctg_id + "\t" + str(ctg_len) + "\n",
                    )


class Tools(StrEnum):
    """Tools."""

    PBF = "pbf"
    HY = "hy"
    MOB = "mob"
    GP = "gp"


class Args:
    """Arguments."""

    TOOL = typer.Option("--tool", help="Tool")
    ASSEMBLY = typer.Option("--assembly", help="Path to assembly gfa file")
    RESULTS = typer.Option("--results", help="Path to binning results file")
    OUTDIR = typer.Option("--outdir", help="Output directory")
    OUTFILE = typer.Option("--outfile", help="Name of output TSV file")


@APP.command()
def main(
    tool: Annotated[Tools, Args.TOOL],
    gfa: Annotated[Path, Args.ASSEMBLY],
    results: Annotated[Path, Args.RESULTS],
    outdir: Annotated[Path, Args.OUTDIR],
    outfile: Annotated[Path, Args.OUTFILE],
) -> None:
    """Format binning results to PlasEval input."""
    assembly = Assembly(gfa)
    outdir.mkdir(parents=True, exist_ok=True)
    bins_out_path = outdir / outfile

    match tool:
        case Tools.PBF:
            format_pbf(results, bins_out_path, assembly)
        case Tools.HY:
            format_hy(results, bins_out_path, assembly)
        case Tools.MOB:
            format_mob(results, bins_out_path, assembly)
        case Tools.GP:
            format_gplas(results, bins_out_path, assembly)

    rprint("[green]Output written to:[/green]", bins_out_path)


if __name__ == "__main__":
    APP()
