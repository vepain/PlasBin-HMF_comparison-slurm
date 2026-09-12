"""Ground truth of the short-read contigs, ported from Tomas Vinar's
`ground-truth-new-v2.pl` (scripts/tvinar-scripts/).

Two outputs, as in the original:

- the hybrid contig labels (`hybrid.gfa.csv`): contig,plasmid_score,chrom_score,label,length
- the ground truth of the short contigs (`short.gfa.csv`): the same columns plus
  chr_coverage,pl_coverage,un_coverage,hybrid_mapsto

A hybrid contig is labelled from its Unicycler FASTA header (chromosome=/plasmid= if
present, else >1 Mb means chromosome, else circular means plasmid), optionally refined
by a supplementary CSV (his `hybrid.ref.csv`, from mapping the hybrid contigs against a
reference database we do not have).

A short contig is labelled from how many of its bases are covered by hybrid contigs of
each label, counting only alignments that pass the same filter as the original.
"""

import argparse
import csv
import gzip
import re
from pathlib import Path

# class -> (plasmid_score, chrom_score, label)
CLASSES = {
    "chr": (0, 1, "chromosome"),
    "pl": (1, 0, "plasmid"),
    "amb": (1, 1, "ambiguous"),
    "un": (0, 0, "unlabeled"),
}
PLASMID_LENGTH_THRESHOLD = 1_000_000  # a contig longer than this is the chromosome
PHIX_LENGTH = 5386                    # illumina control phage
LENGTH_RE = re.compile(r"length=(\d+)")


def open_text(path: Path):
    """Open a plain or gzipped text file."""
    return gzip.open(path, "rt") if path.suffix == ".gz" else path.open()


def fasta_headers(fasta: Path) -> list[tuple[str, int, str]]:
    """(contig id, length, full header) of every record of a FASTA."""
    records = []
    with open_text(fasta) as handle:
        for line in handle:
            if not line.startswith(">"):
                continue
            header = line.rstrip("\n")
            name = header[1:].split()[0]
            match = LENGTH_RE.search(header)
            records.append((name, int(match.group(1)) if match else 0, header))
    return records


def gfa_contigs(gfa: Path) -> list[tuple[str, int]]:
    """(contig id, sequence length) of every segment of a GFA, in file order."""
    contigs = []
    with open_text(gfa) as handle:
        for line in handle:
            if line.startswith("S\t"):
                fields = line.rstrip("\n").split("\t")
                contigs.append((fields[1], len(fields[2])))
    return contigs


def supplementary(csv_path: Path | None) -> dict[str, dict[str, int]]:
    """Coverages per hybrid contig from a supplementary CSV, if there is one."""
    if csv_path is None or not csv_path.is_file():
        return {}
    with csv_path.open(newline="") as handle:
        return {
            row["contig"]: {k: int(row[k]) for k in ("length", "chr_coverage", "pl_coverage", "un_coverage")}
            for row in csv.DictReader(handle)
        }


def classify_hybrid(header: str, length: int, suppl: dict[str, int] | None) -> str:
    """Label of a hybrid contig, from its FASTA header and any supplementary coverages."""
    if "chromosome=true" in header:
        klass = "chr"
    elif "plasmid=true" in header:
        klass = "pl"
    elif length > PLASMID_LENGTH_THRESHOLD:
        klass = "chr"
    elif "circular=true" in header or ("plasmid" in header and "complete" in header):
        klass = "pl"
    else:
        klass = "un"

    if not suppl:
        return klass

    chrom, plasmid, unlabeled = suppl["chr_coverage"], suppl["pl_coverage"], suppl["un_coverage"]
    if klass == "un":
        # only a stringent match in the supplementary information may label it
        if length >= 10_000 and plasmid >= 0.8 * length and chrom < 0.2 * length and unlabeled < 0.2 * length:
            klass = "pl"
        if length >= 100_000 and chrom >= 0.8 * length and plasmid < 0.2 * length and unlabeled < 0.2 * length:
            klass = "chr"
    else:
        # drop a label the supplementary information contradicts
        if klass == "chr" and chrom > 0 and plasmid > chrom:
            klass = "un"
        if klass == "pl" and plasmid > 0 and chrom > plasmid:
            klass = "un"
        if klass == "pl" and length == PHIX_LENGTH and plasmid == 0:
            klass = "un"
    return klass


def covered_bases(intervals: list[tuple[int, int]]) -> int:
    """Bases covered by the union of half-open intervals."""
    total, current_end = 0, 0
    for start, end in sorted(intervals):
        start = max(start, current_end)
        if end > current_end:
            total += end - start
            current_end = end
    return total


def classify_short(chrom: int, plasmid: int, unlabeled: int) -> str:
    """Label of a short contig from its covered bases per hybrid label."""
    if chrom > 0 and plasmid + unlabeled < 0.2 * chrom:
        return "chr"
    if plasmid > 0 and chrom + unlabeled < 0.2 * plasmid:
        return "pl"
    if chrom > 0 and plasmid > 0 and unlabeled < 0.2 * (chrom + plasmid):
        return "amb"
    return "un"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--paf", type=Path, required=True, help="short contigs vs hybrid contigs")
    parser.add_argument("--short-gfa", type=Path, required=True, help="short read assembly GFA")
    parser.add_argument("--hybrid-fasta", type=Path, required=True, help="hybrid assembly FASTA (Unicycler headers)")
    parser.add_argument("--supplementary", type=Path, default=None, help="optional hybrid.ref.csv")
    parser.add_argument("--out-hybrid-csv", type=Path, required=True, help="output hybrid contig labels")
    parser.add_argument("--out-gt-csv", type=Path, required=True, help="output ground truth")
    parser.add_argument("--min-similarity", type=float, default=0.98, help="required matches/alignment length")
    args = parser.parse_args()

    # ---- label the hybrid contigs ------------------------------------------------
    suppl = supplementary(args.supplementary)
    hybrid_class: dict[str, str] = {}
    args.out_hybrid_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.out_hybrid_csv.open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["contig", "plasmid_score", "chrom_score", "label", "length"])
        for name, length, header in fasta_headers(args.hybrid_fasta):
            klass = classify_hybrid(header, length, suppl.get(name))
            hybrid_class[name] = klass
            writer.writerow([name, *CLASSES[klass], length])

    # ---- coverage of every short contig, per hybrid label -------------------------
    intervals: dict[str, dict[str, list[tuple[int, int]]]] = {}
    mapsto: dict[str, set[str]] = {}
    with args.paf.open() as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            query, qlen, qstart, qend = fields[0], int(fields[1]), int(fields[2]), int(fields[3])
            target, matches, aln_len = fields[5], int(fields[9]), int(fields[10])
            worthy = (matches > 1000 or matches / qlen > 0.8) and matches / aln_len >= args.min_similarity
            if not worthy:
                continue
            klass = hybrid_class.get(target, "un")
            intervals.setdefault(query, {}).setdefault(klass, []).append((qstart, qend))
            mapsto.setdefault(query, set()).add(target)

    # ---- write the ground truth ---------------------------------------------------
    args.out_gt_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.out_gt_csv.open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            ["contig", "plasmid_score", "chrom_score", "label", "length",
             "chr_coverage", "pl_coverage", "un_coverage", "hybrid_mapsto"],
        )
        for name, length in gfa_contigs(args.short_gfa):
            per_class = intervals.get(name, {})
            chrom = covered_bases(per_class.get("chr", []))
            plasmid = covered_bases(per_class.get("pl", []))
            unlabeled = covered_bases(per_class.get("un", []))
            klass = classify_short(chrom, plasmid, unlabeled)
            # the original joins Perl hash keys, whose order is arbitrary: sort instead
            hits = ";".join(sorted(mapsto.get(name, ()), key=lambda c: (len(c), c)))
            writer.writerow([name, *CLASSES[klass], length, chrom, plasmid, unlabeled, hits])


if __name__ == "__main__":
    main()
