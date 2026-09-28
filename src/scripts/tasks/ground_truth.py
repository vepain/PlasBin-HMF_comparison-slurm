"""Infer ground-truth chromosome/plasmid labels for an assembly.

Compares a short-read (or single) assembly against a hybrid reference
assembly using minimap2, then classifies each contig of the evaluated
assembly as chromosome, plasmid, ambiguous, or unlabeled based on how
much of it is covered by alignments to reference contigs of each class.
"""

from __future__ import annotations

import csv
import gzip
import logging
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

import typer

if TYPE_CHECKING:
    from collections.abc import Iterator
    from io import TextIOWrapper

app = typer.Typer(add_completion=False)
logger = logging.getLogger(__name__)

DEFAULT_SIMILARITY = 0.98
DEFAULT_OUTPUT_SUFFIX = "gfa.csv"

# Threshold above which a circular-or-untagged contig is assumed to be a
# chromosome rather than a plasmid.
PLASMID_LENGTH_THRESHOLD = 1_000_000

# Length/coverage of the Illumina PhiX control, which is spiked into some
# sequencing runs and should never be labeled as a real plasmid.
PHIX_LENGTH = 5386

HEADER_ID_RE = re.compile(r"^>(\S+)")
HEADER_LENGTH_RE = re.compile(r"length=(\d+)")


@dataclass(frozen=True, slots=True)
class LabelInfo:
    """Score/label triple written out for each classification bucket."""

    plasmid_score: int
    chrom_score: int
    label: str


WRITEOUT: dict[str, LabelInfo] = {
    "chr": LabelInfo(0, 1, "chromosome"),
    "pl": LabelInfo(1, 0, "plasmid"),
    "amb": LabelInfo(1, 1, "ambiguous"),
    "un": LabelInfo(0, 0, "unlabeled"),
}


@dataclass(slots=True)
class ContigSupplement:
    """Supplementary per-contig coverage info loaded from hybrid.ref.csv."""

    length: int
    pl_coverage: float
    chr_coverage: float
    un_coverage: float


@dataclass(slots=True)
class MatchAccumulator:
    """Alignment intervals and target ids collected for one query contig."""

    intervals_by_class: dict[str, list[tuple[int, int]]] = field(default_factory=dict)
    target_ids: set[str] = field(default_factory=set)


def convert_fasta_with_length(src_gz: Path, dest: Path) -> None:
    """Rewrite a gzipped FASTA file, annotating each header with its length."""
    logger.info("Creating %s from %s...", dest, src_gz)
    with gzip.open(src_gz, "rt") as src, dest.open("w") as out:
        name: str | None = None
        seq_chunks: list[str] = []
        for line in src:
            line = line.rstrip("\n")
            if line.startswith(">"):
                if name is not None:
                    _write_fasta_record(out, name, seq_chunks)
                name = line
                seq_chunks = []
            else:
                seq_chunks.append(line)
        if name is not None:
            _write_fasta_record(out, name, seq_chunks)


def _write_fasta_record(out: TextIOWrapper, name: str, seq_chunks: list[str]) -> None:
    seq = "".join(seq_chunks)
    out.write(f"{name} length={len(seq)}\n")  # type: ignore[attr-defined]
    out.write(f"{seq}\n")  # type: ignore[attr-defined]


def convert_gfa_to_fasta(src_gz: Path, dest: Path) -> None:
    """Extract segment (S) lines from a gzipped GFA file into a FASTA file."""
    logger.info("Creating %s from %s...", dest, src_gz)
    with gzip.open(src_gz, "rt") as src, dest.open("w") as out:
        for line in src:
            if not line.startswith("S"):
                continue
            parts = line.rstrip("\n").split("\t")
            name, seq = parts[1], parts[2]
            out.write(f">{name} length={len(seq)}\n")
            out.write(f"{seq}\n")


def run_minimap2(reference: Path, query_fasta: Path, paf_out: Path) -> None:
    """Align query_fasta against reference with minimap2, writing a PAF file."""
    cmd = [
        "minimap2",
        "-x",
        "map-ont",
        "-p",
        "0.8",
        "-c",
        "-I",
        "500M",
        "--rmq=no",
        "--no-long-join",
        str(reference),
        str(query_fasta),
    ]
    logger.info("%s > %s", " ".join(cmd), paf_out)
    with paf_out.open("w") as handle:
        subprocess.run(cmd, stdout=handle, check=True)  # noqa: S603


def load_supplement_csv(path: Path) -> dict[str, ContigSupplement]:
    """Load per-contig coverage hints keyed by contig id (first CSV column)."""
    supplement: dict[str, ContigSupplement] = {}
    if not path.exists():
        logger.warning("Supplementary CSV %s does not exist!", path)
        return supplement

    with path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            return supplement
        id_column = reader.fieldnames[0]
        for row in reader:
            contig_id = row[id_column]
            supplement[contig_id] = ContigSupplement(
                length=int(row["length"]),
                pl_coverage=float(row["pl_coverage"]),
                chr_coverage=float(row["chr_coverage"]),
                un_coverage=float(row["un_coverage"]),
            )
    return supplement


def parse_fasta_headers(gz_path: Path) -> Iterator[tuple[str, str, int]]:
    """Yield (id, full_header_line, length) for each record in a gzipped FASTA."""
    with gzip.open(gz_path, "rt") as handle:
        for line in handle:
            if not line.startswith(">"):
                continue
            id_match = HEADER_ID_RE.match(line)
            length_match = HEADER_LENGTH_RE.search(line)
            if id_match is None or length_match is None:
                continue
            yield id_match.group(1), line, int(length_match.group(1))


def classify_hybrid_contig(
    contig_id: str,
    header: str,
    length: int,
    supplement: ContigSupplement | None,
    plasmid_length_threshold: int,
) -> str:
    """Classify a hybrid-reference contig as chr/pl/un, refined by supplement."""
    if "chromosome=true" in header:
        label = "chr"
    elif "plasmid=true" in header:
        label = "pl"
    elif length > plasmid_length_threshold:
        label = "chr"
    elif "circular=true" in header or ("plasmid" in header and "complete" in header):
        label = "pl"
    else:
        label = "un"

    if supplement is None:
        return label

    if supplement.length != length:
        msg = f"Somethig is rotten, incompatible contig lengths {contig_id}"
        raise ValueError(msg)

    if label == "un":
        if (
            length >= 10_000
            and supplement.pl_coverage >= 0.8 * length
            and supplement.chr_coverage < 0.2 * length
            and supplement.un_coverage < 0.2 * length
        ):
            label = "pl"
        if (
            length >= 100_000
            and supplement.chr_coverage >= 0.8 * length
            and supplement.pl_coverage < 0.2 * length
            and supplement.un_coverage < 0.2 * length
        ):
            label = "chr"
    else:
        if (
            label == "chr"
            and supplement.chr_coverage > 0
            and supplement.pl_coverage > supplement.chr_coverage
        ):
            label = "un"
        if (
            label == "pl"
            and supplement.pl_coverage > 0
            and supplement.chr_coverage > supplement.pl_coverage
        ):
            label = "un"
        # Illumina PhiX control shouldn't be counted as a real plasmid.
        if label == "pl" and length == PHIX_LENGTH and supplement.pl_coverage == 0:
            label = "un"

    return label


def build_hybrid_classification(
    reference: Path,
    supplement: dict[str, ContigSupplement],
    plasmid_length_threshold: int,
    output_csv: Path,
) -> dict[str, str]:
    """Classify every contig in the hybrid reference and write a summary CSV."""
    classification: dict[str, str] = {}
    with output_csv.open("w", newline="") as out:
        writer = csv.writer(out)
        writer.writerow(["contig", "plasmid_score", "chrom_score", "label", "length"])
        for contig_id, header, length in parse_fasta_headers(reference):
            label = classify_hybrid_contig(
                contig_id=contig_id,
                header=header,
                length=length,
                supplement=supplement.get(contig_id),
                plasmid_length_threshold=plasmid_length_threshold,
            )
            classification[contig_id] = label
            info = WRITEOUT[label]
            writer.writerow(
                [contig_id, info.plasmid_score, info.chrom_score, info.label, length],
            )
    return classification


def parse_paf(
    paf_file: Path,
    classification: dict[str, str],
    similarity: float,
) -> dict[str, MatchAccumulator]:
    """Collect per-query alignment intervals, grouped by reference contig class."""
    matches: dict[str, MatchAccumulator] = {}
    with paf_file.open() as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            query_id = parts[0]
            query_len = int(parts[1])
            query_start = int(parts[2])
            query_end = int(parts[3])
            target_id = parts[5]
            num_matches = float(parts[9])
            aln_len = float(parts[10])

            is_long_enough = num_matches > 1000 or num_matches / query_len > 0.8
            is_similar_enough = num_matches / aln_len >= similarity
            if not (is_long_enough and is_similar_enough):
                continue

            match_class = classification.get(target_id, "un")
            acc = matches.setdefault(query_id, MatchAccumulator())
            acc.intervals_by_class.setdefault(match_class, []).append(
                (query_start, query_end),
            )
            acc.target_ids.add(target_id)
    return matches


def compute_coverage(intervals: list[tuple[int, int]]) -> int:
    """Sum the length covered by a set of possibly-overlapping intervals."""
    total = 0
    cur_end = 0
    for start, end in sorted(intervals):
        start = max(start, cur_end)
        if end > cur_end:
            total += end - start
            cur_end = end
    return total


def classify_query_contig(chr_cov: int, pl_cov: int, un_cov: int) -> str:
    """Classify an evaluated-assembly contig from its per-class coverage."""
    if chr_cov > 0 and (pl_cov + un_cov) < 0.2 * chr_cov:
        return "chr"
    if pl_cov > 0 and (chr_cov + un_cov) < 0.2 * pl_cov:
        return "pl"
    if chr_cov > 0 and pl_cov > 0 and un_cov < 0.2 * (chr_cov + pl_cov):
        return "amb"
    return "un"


def write_query_classification(
    query_fasta: Path,
    matches: dict[str, MatchAccumulator],
    output_csv: Path,
) -> None:
    """Classify every contig of the evaluated assembly and write the result CSV."""
    with query_fasta.open() as handle, output_csv.open("w", newline="") as out:
        writer = csv.writer(out)
        writer.writerow(
            [
                "contig",
                "plasmid_score",
                "chrom_score",
                "label",
                "length",
                "chr_coverage",
                "pl_coverage",
                "un_coverage",
                "hybrid_mapsto",
            ],
        )
        for line in handle:
            if not line.startswith(">"):
                continue
            id_match = HEADER_ID_RE.match(line)
            length_match = HEADER_LENGTH_RE.search(line)
            if id_match is None or length_match is None:
                continue
            contig_id = id_match.group(1)
            length = int(length_match.group(1))

            acc = matches.get(contig_id, MatchAccumulator())
            chr_cov = compute_coverage(acc.intervals_by_class.get("chr", []))
            pl_cov = compute_coverage(acc.intervals_by_class.get("pl", []))
            un_cov = compute_coverage(acc.intervals_by_class.get("un", []))

            label = classify_query_contig(chr_cov, pl_cov, un_cov)
            info = WRITEOUT[label]
            mapsto = ";".join(sorted(acc.target_ids))
            writer.writerow(
                [
                    contig_id,
                    info.plasmid_score,
                    info.chrom_score,
                    info.label,
                    length,
                    chr_cov,
                    pl_cov,
                    un_cov,
                    mapsto,
                ],
            )


@app.command()
def main(
    sample_dir: Path = typer.Argument(  # noqa: B008
        ...,
        exists=True,
        file_okay=False,
        help="Sample directory containing the assemblies.",
    ),
    assembly: str = typer.Argument(
        ...,
        help="Assembly name, without the .gfa.gz/.fasta.gz suffix.",
    ),
    reference_file: Path | None = typer.Argument(  # noqa: B008
        None,
        help="Reference fasta.gz to compare against. Defaults to hybrid.fasta.gz in sample_dir.",
    ),
    similarity: float = typer.Option(
        DEFAULT_SIMILARITY,
        "-s",
        "--similarity",
        help="Required similarity for a match.",
    ),
    output_suffix: str = typer.Option(
        DEFAULT_OUTPUT_SUFFIX,
        "-o",
        "--output-suffix",
        help="Suffix appended to the output file names.",
    ),
) -> None:
    """Add ground-truth inference about an assembly by comparison to a reference."""
    logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stderr)

    logger.info("Required similarity: %s", similarity)
    logger.info("Output suffix: %s", output_suffix)

    supplement_csv: Path | None
    if reference_file is not None:
        reference = reference_file
        supplement_csv = None
        save_reference_csv = Path("/dev/null")
    else:
        reference = sample_dir / "hybrid.fasta.gz"
        supplement_csv = sample_dir / "hybrid.ref.csv"
        save_reference_csv = sample_dir / "hybrid.gfa.csv"

    if not (sample_dir / "done").exists():
        logger.warning("Directory not finished")
        raise typer.Exit(code=0)

    gfa_path = sample_dir / f"{assembly}.gfa.gz"
    fasta_path = sample_dir / f"{assembly}.fasta.gz"
    if not gfa_path.exists() and not fasta_path.exists():
        logger.warning(
            "Missing short read assembly (neither %s nor %s)",
            gfa_path.name,
            fasta_path.name,
        )
        raise typer.Exit(code=0)

    if not reference.exists():
        logger.warning("Missing reference %s", reference)
        raise typer.Exit(code=0)

    query_fasta = sample_dir / f"temp-short-{assembly}.fasta"
    paf_file = sample_dir / f"{assembly}.{output_suffix}.paf"

    if gfa_path.exists():
        convert_gfa_to_fasta(gfa_path, query_fasta)
    else:
        convert_fasta_with_length(fasta_path, query_fasta)

    run_minimap2(reference, query_fasta, paf_file)

    supplement = (
        load_supplement_csv(supplement_csv) if supplement_csv is not None else {}
    )

    classification = build_hybrid_classification(
        reference=reference,
        supplement=supplement,
        plasmid_length_threshold=PLASMID_LENGTH_THRESHOLD,
        output_csv=save_reference_csv,
    )

    matches = parse_paf(paf_file, classification, similarity)

    output_csv = sample_dir / f"{assembly}.{output_suffix}"
    write_query_classification(query_fasta, matches, output_csv)

    query_fasta.unlink()


if __name__ == "__main__":
    app()
