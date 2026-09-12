#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin); use lib "$Bin";  # include script directory in path
use Getopt::Std;
#use Data::Dumper;

my $reqsimilarity = 0.98;
my $outsuffix = "gfa.csv";

my $usage = "
$0 sample_dir assembly [reference_file.fasta.gz]

Add inference about ground truth on assembly in the sample directory
Evaluated assembly file: assembly.gfa.gz or assembly.fasta.gz
Comparing to a hybrid assembly: hybrid.fasta.gz
unless reference_file.fasta.gz is specified

Options:
-s similarity    required similarity for a match (default: $reqsimilarity)
-o output_suffix in the output, add the following suffix (default: $outsuffix)
    ";

my %Options;
getopts('s:o:',\%Options);
$reqsimilarity = $Options{'s'} if defined $Options{'s'};
$outsuffix = $Options{'o'} if defined $Options{'o'};


my $dir = shift or die $usage;
my $assembly = shift or die $usage;

my $reference = "$dir/hybrid.fasta.gz";
my $supplcsv = "$dir/hybrid.ref.csv";
my $savereferencecsv = "$dir/hybrid.gfa.csv";
my $x = shift;
if (defined $x) {
    $reference = $x;
    $savereferencecsv = "/dev/null";
    $supplcsv = "";
}

# threshold for classifying circular contigs as plasmids
my $plasmidthr = 1000000;

my %writeout = (
    'chr' => [0,1,"chromosome"],
    'pl' => [1,0,"plasmid"],
    'amb' => [1,1,"ambiguous"],
    'un' => [0,0,"unlabeled"]);


print STDERR "Required similarity: $reqsimilarity\n";
print STDERR "Output suffix: $outsuffix\n";


unless (-e "$dir/done") {
    warn "Directory not finished";
    exit;
}

unless (-e "$dir/$assembly.gfa.gz" || -e "$dir/$assembly.fasta.gz") {
    warn "Missing short read assembly (neithe $assembly.gfa.gz nor fasta.gz)" ;
    exit;
}

unless (-e "$reference") {
    warn "Missing reference $reference";
    exit;
}

my $tempshortfa = "$dir/temp-short-$assembly.fasta";
my $paffile = "$dir/$assembly.$outsuffix.paf";

if (-e "$dir/$assembly.gfa.gz") {
    gfa2fasta("$dir/$assembly.gfa.gz",$tempshortfa);
} else {
    fasta2fasta("$dir/$assembly.fasta.gz",$tempshortfa);
}

my_run("minimap2 -x map-ont -p 0.8 -c -I 500M --rmq=no --no-long-join $reference $tempshortfa > $paffile");


my %supplinfo;
# read supplementary information from supplementary csv
if ($supplcsv) {
    if (-e $supplcsv) {
	open SCSV, "< $supplcsv";
	my $h = <SCSV>; chomp $h; my @headers = split ",",$h;
	while (my $line = <SCSV>) {
	    chomp $line;
	    my @parts = split ",",$line;
	    for (my $i=0; $i<@parts; $i++) {
		$supplinfo{$parts[0]}{$headers[$i]} = $parts[$i];
	    }
	}
	close SCSV;
    } else {
	warn "Supplementary CSV $supplcsv does not exist!";
    }
}


# classify hybrid assembly contigs
# save the hybrid assembly csv for reference
my %classify_hybrid;
open IN, "gunzip -c $reference |";
open OUT, ">$savereferencecsv";
print OUT join(",","contig","plasmid_score","chrom_score","label","length"),"\n"; 

while (my $line = <IN>) {
    next unless $line =~ /^>/;
    $line =~ /^>(\S+)/;
    my $id = $1;
    $line =~ /length=(\d+)/;
    my $length = $1;

    # initial classification based on length and circularity

    my $class;
    if ($line =~ /chromosome=true/) {
	$class = "chr";
    } elsif ($line=~ /plasmid=true/) {
	$class = "pl";
    } elsif (0+$length > $plasmidthr) {
	$class = "chr";
    } elsif ($line =~ /circular=true/ || ($line =~ /plasmid/ && $line =~ /complete/)) {
	$class = "pl";
    } else {
	$class = "un";
    }

    if (defined $supplinfo{$id}) {
	my $si = $supplinfo{$id};
        die "Somethig is rotten, incompatible contig lengths $id"
	    unless $si->{'length'} == $length;
    
	if ($class eq "un") {
	    # attempt to classify based on stringent
	    # criteria in supplementary information
	    $class = "pl" if $length >= 10000 &&
		$si->{'pl_coverage'} >= 0.8 * $length &&
		$si->{'chr_coverage'} < 0.2 * $length &&
		$si->{'un_coverage'} < 0.2 * $length;
	    $class = "chr" if $length >= 100000 &&
		$si->{'chr_coverage'} >= 0.8 * $length &&
		$si->{'pl_coverage'} < 0.2 * $length &&
		$si->{'un_coverage'} < 0.2 * $length;	    
	} else {
	    # verify that initial classificaton does not contradict
	    # supplementary information; if it does, reset classification
	    $class = "un" if $class eq "chr" && $si->{'chr_coverage'} > 0 &&
		$si->{'pl_coverage'} > $si->{'chr_coverage'};
	    $class = "un" if $class eq "pl" && $si->{'pl_coverage'} > 0 &&
		$si->{'chr_coverage'} > $si->{'pl_coverage'};
	    # illumina control phage
	    $class = "un" if $class eq "pl" && $length == 5386 &&
		$si->{'pl_coverage'} == 0;
	}
    }
    
    $classify_hybrid{$id} = $class;

    print OUT join(",",$id,@{$writeout{$classify_hybrid{$id}}},$length),"\n";
}
close IN;
close OUT;

my %matchlist;
my %matchids;
#create overview of matches from paf file
open IN,"< $paffile";
while (my $line = <IN>) {
    chomp $line;
    my @parts = split("\t",$line);
    my ($qid,$qstart,$qend,$tid,$qlen,$matches,$alnlen) = ($parts[0],$parts[2],$parts[3],$parts[5],$parts[1],$parts[9],$parts[10]);
    $matches = 0.0+$matches;
    if ((($matches > 1000) || ($matches / $qlen > 0.8)) && ($matches/$alnlen >= $reqsimilarity)) {
	# this is a worthy match
	my $matchclass;
	if (defined $classify_hybrid{$tid}) {
	    $matchclass = $classify_hybrid{$tid};
	} else {
	    $matchclass = "un";
	}

	push @{$matchlist{$qid}{$matchclass}},[$qstart,$qend];
	$matchids{$qid}{$tid}+=1;
    }
}
close IN;

my %nummatches;
# compute coverage of each contig by each type of alignment
foreach my $qid (keys(%matchlist)) {
    my $curmatchlist = $matchlist{$qid};
    foreach my $type (keys(%$curmatchlist)) {
	$nummatches{$qid}{$type} = compute_coverage($curmatchlist->{$type});
    }
}


# parse through fasta file and create gold standard output
    
open IN, "<$tempshortfa";
open OUT, "> $dir/$assembly.$outsuffix";
print OUT join(",","contig","plasmid_score","chrom_score","label","length","chr_coverage","pl_coverage","un_coverage","hybrid_mapsto"),"\n"; 
while (my $line = <IN>) {
    next unless $line =~ /^>/;
    $line =~ /^>(\S+)/;
    my $id = $1;
    $line =~ /length=(\d+)/;
    my $length = $1;

    $nummatches{$id}{'chr'} +=0;
    $nummatches{$id}{'pl'} +=0;
    $nummatches{$id}{'un'} +=0;

    my ($chr,$pl,$un) = ($nummatches{$id}{'chr'},$nummatches{$id}{'pl'},$nummatches{$id}{'un'}); 

    my $class;

    if ($chr>0 && ($pl + $un < 0.2 * $chr)) {
	$class = "chr";
    } elsif ($pl>0 && ($chr + $un < 0.2 * $pl)) {
	$class = "pl";
    } elsif ($chr>0 && $pl>0 && ($un < 0.2 * ($chr + $pl))) {
	$class = "amb";
    } else {
	$class = "un";
    }
    
    $matchids{$id} = {} unless defined $matchids{$id};    
    print OUT join(",",$id,@{$writeout{$class}},$length,$chr,$pl,$un,join(";",keys(%{$matchids{$id}}))),"\n";
}
close IN;
close OUT;

unlink($tempshortfa);


sub fasta2fasta
{
    my ($fagz,$fa)=@_;
    print STDERR "Creating $fa from $fagz...\n";

    my $in;
    my $out;

    open $in, "gunzip -c $fagz |";
    open $out, "> $fa";

    my $name; my $seq="";
    
    while (my $line = <$in>) {
	chomp $line;
	if ($line =~ /^>/) {
	    if (defined $name) {
		print $out "$name length=",length($seq),"\n";
		print $out $seq,"\n";
	    }
	    $name = $line;
	    $seq = "";
	} else {
	    $seq.=$line;
	}
    }
    if (defined $name) {
	print $out "$name length=",length($seq),"\n";
	print $out $seq,"\n";
    }
    close $in;
    close $out;
}


sub gfa2fasta
{
    my ($gfagz,$fa)=@_;
    print STDERR "Creating $fa from $gfagz...\n";
    
    my $in;
    my $out;
    
    open $in, "gunzip -c $gfagz |";
    open $out, "> $fa";
    
    while (my $line = <$in>) {
	next unless $line =~ /^S/;
	chomp $line;
	my @parts = split("\t",$line);
	my $name = $parts[1];
	my $seq = $parts[2];
	print $out ">$name length=",length($seq),"\n";
	print $out $seq,"\n";
    }

    close $in;
    close $out;
}

sub compute_coverage
{
    my ($intervals) = @_;
    my @sorted = sort { $a->[0] <=> $b->[0] } @$intervals;
 
    my $sum = 0;
    my $curend = 0;

    for (my $i=0; $i<@sorted; $i++) {
	my $start = $sorted[$i][0]; # start is 0-based
	my $end = $sorted[$i][1];   # end is 1-based
        $start=$curend if ($start<$curend);
	if ($end > $curend) {
	    $sum += ($end-$start);
	    $curend = $end;
	}
    }
    
    return $sum;
}

sub my_run
{
    my ($run, $die) = @_;
    if(!defined($die)) { $die = 1; }

    my $short = substr($run, 0, 20);

    print STDERR $run, "\n";
    my $res = system($run);
    if($res<0) {
	die "Error in program '$short...' '$!'";
    }
    if($? && $die) {
	my $exit  = $? >> 8;
	my $signal  = $? & 127;
	my $core = $? & 128;

	die "Error in program '$short...' "
	    . "(exit: $exit, signal: $signal, dumped: $core)\n\n ";
    }
}
