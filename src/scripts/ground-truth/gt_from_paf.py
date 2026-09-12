"""Build a ground truth CSV from a short-contigs -> hybrid-contigs PAF.

Reproduces the format of Tomas' `short.gfa.csv`:

    contig,plasmid_score,chrom_score,label,length,chr_coverage,pl_coverage,un_coverage,hybrid_mapsto

- coverages are aligned base pairs on the short contig, per hybrid-contig label,
  each the union of the alignment intervals (so overlapping alignments are not
  counted twice). The chromosome and plasmid unions may overlap each other.
- un_coverage is the coverage by hybrid contigs labelled neither chromosome nor
  plasmid, so it is 0 when every hybrid contig is labelled (not the uncovered part
  of the contig).
- scores are 0/1 flags; a contig covered by both labels is 'ambiguous', one covered
  by neither is 'unlabeled'.
"""

import argparse
import csv
import gzip
from pathlib import Path

CHROMOSOME = "chromosome"
PLASMID = "plasmid"
UNLABELED = "unlabeled"


def open_maybe_gzip(path: Path):
    """Open a plain or gzipped text file."""
    if path.suffix == ".gz":
        return gzip.open(path, "rt")
    return path.open()


def contig_lengths(gfa: Path) -> dict[str, int]:
    """Length of every segment of a GFA, from its LN tag or its sequence."""
    lengths: dict[str, int] = {}
    with open_maybe_gzip(gfa) as handle:
        for line in handle:
            if not line.startswith("S\t"):
                continue
            fields = line.rstrip("\n").split("\t")
            name, seq = fields[1], fields[2]
            length = len(seq) if seq != "*" else 0
            for tag in fields[3:]:
                if tag.startswith("LN:i:"):
                    length = int(tag[5:])
            lengths[name] = length
    return lengths


def hybrid_labels(csv_path: Path) -> dict[str, str]:
    """Label ('chromosome'/'plasmid'/...) of every hybrid contig."""
    with csv_path.open(newline="") as handle:
        return {row["contig"]: row["label"] for row in csv.DictReader(handle)}


def union_length(intervals: list[tuple[int, int]]) -> int:
    """Total length covered by the union of half-open intervals."""
    total, current_end = 0, -1
    for start, end in sorted(intervals):
        if start > current_end:
            total += end - start
            current_end = end
        elif end > current_end:
            total += end - current_end
            current_end = end
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--paf", type=Path, required=True, help="short vs hybrid PAF")
    parser.add_argument("--short-gfa", type=Path, required=True, help="short assembly GFA")
    parser.add_argument("--hybrid-labels", type=Path, required=True, help="hybrid contig labels CSV")
    parser.add_argument("--out", type=Path, required=True, help="output ground truth CSV")
    args = parser.parse_args()

    lengths = contig_lengths(args.short_gfa)
    labels = hybrid_labels(args.hybrid_labels)

    # per short contig: intervals per label, all intervals, and the hybrid contigs hit
    by_label: dict[str, dict[str, list[tuple[int, int]]]] = {}
    mapsto: dict[str, list[str]] = {}

    with args.paf.open() as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            query, start, end, target = fields[0], int(fields[2]), int(fields[3]), fields[5]
            label = labels.get(target, UNLABELED)
            if label not in (CHROMOSOME, PLASMID):
                label = UNLABELED
            by_label.setdefault(query, {}).setdefault(label, []).append((start, end))
            hits = mapsto.setdefault(query, [])
            if target not in hits:
                hits.append(target)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            ["contig", "plasmid_score", "chrom_score", "label", "length",
             "chr_coverage", "pl_coverage", "un_coverage", "hybrid_mapsto"],
        )
        for contig, length in lengths.items():
            per_label = by_label.get(contig, {})
            chr_cov = union_length(per_label.get(CHROMOSOME, []))
            pls_cov = union_length(per_label.get(PLASMID, []))
            un_cov = union_length(per_label.get(UNLABELED, []))
            chrom_score = 1 if chr_cov > 0 else 0
            plasmid_score = 1 if pls_cov > 0 else 0
            if chrom_score and plasmid_score:
                label = "ambiguous"
            elif chrom_score:
                label = CHROMOSOME
            elif plasmid_score:
                label = PLASMID
            else:
                label = UNLABELED
            writer.writerow(
                [contig, plasmid_score, chrom_score, label, length,
                 chr_cov, pls_cov, un_cov, ";".join(mapsto.get(contig, []))],
            )


if __name__ == "__main__":
    main()
