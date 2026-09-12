#! /usr/bin/perl -w
use strict;
use File::Temp qw / tempdir /;
use Data::Dumper qw / Dumper /;

my $usage = "
$0 source.[gfa|gfa.gz|fasta|fasta.gz] target.[gfa|gfa.gz|fasta|fasta.gz] output1.csv > output2.csv 

Remap plASgraph output from the source contigs to target contigs.
output1.csv - plASgraph output for source contigs
output2.csv - plASgraph output for target contigs

";

my $source = shift or die $usage;
my $target = shift or die $usage;
my $csv = shift or die $usage;

#my $tmpdir = tempdir( CLEANUP => 1 );
my $tmpdir = "tmp";
my $usource = "$tmpdir/source.fa";
my $utarget = "$tmpdir/target.fa";
my $paf = "$tmpdir/minimap.paf";
my $mappingthreshold = 0.99;
my $allowedoverlap = 10;

unify_file_format($source,$usource);
unify_file_format($target,$utarget);

my %contiglen;

## read the target contigs - names and lengths
my $tf;
open $tf,"<$utarget" or die "Cannot read $utarget";
my $cname;
while (my $line = <$tf>) {
    chomp $line;
    if ($line =~ /^>\s*(\S*)/) {
	$cname = $1;
	$contiglen{$cname} = 0;
    } else {
	$contiglen{$cname} += length($line)
	    if defined $cname;
    }
}
close $tf;

## map target contigs to source contigs
my_run("minimap2 -x map-ont -c $usource $utarget > $paf");

my $paff;
my %coverage;
open $paff,"< $paf" or die "Cannot read $paf";
while (my $line = <$paff>) {
    chomp $line;
    my @parts = split "\t",$line;
    my ($tname,$tlen,$tstart,$tend,$sname,$sidentity) =
	($parts[0],$parts[1],$parts[2],$parts[3],$parts[5],
	 (0.0 + $parts[9]) / $parts[10]);
    next unless $sidentity > $mappingthreshold;
    
    my $triple = { "start" => $tstart, "end" => $tend, "name" => $sname,
                   "identity" => $sidentity };
    push @{$coverage{$tname}},$triple;
    $contiglen{$tname} = $tlen;
}

close $paff;


my %finalmapping;
# process each target contig separately
foreach my $contig (sort keys %contiglen) {
    # start from the longest matching contigs
    # choose greedily one, remove overlapping ones
    my @triples = sort
    { ($b->{"end"}-$b->{"start"}) <=> ($a->{"end"}-$a->{"start"}) }
    @{$coverage{$contig}};

    print STDERR "$contig (",$contiglen{$contig},"):";
    for (my $i=0; $i < @triples; $i++) {
	next if defined $triples[$i]{"ignore"};
	print STDERR " ".$triples[$i]{"name"}." (".($triples[$i]{"end"} - $triples[$i]{"start"}).";",sprintf("%.3f",$triples[$i]{"identity"}),")";
	for (my $j=$i+1; $j < @triples; $j++) {
	    if (overlaplen($triples[$i],$triples[$j]) > $allowedoverlap) {
		$triples[$j]{"ignore"} = 1;
	    }
	}
	push @{$finalmapping{$contig}},$triples[$i];
    }
    print STDERR "\n";
}


## now read the csv file
my %origout;
my $csvf;
open $csvf,"<$csv" or die "Cannot read $csv";
while (my $line = <$csvf>) {
    chomp $line;
    next if $line =~ /^sample,contig/; # skip the header line
    my @parts = split ",",$line;
    next if $parts[3] == 0 && $parts[4] == 0; # skip unclassified contigs
    my $tuple = { "pl" => $parts[3], "chr" => $parts[4] };
    $origout{$parts[1]} = $tuple;
}
close $csvf;

## for each contig compute new scores
print join(",","sample","contig","length","plasmid_score","chrom_score","label"),"\n";
foreach my $contig (sort keys %contiglen) {
    next unless $contiglen{$contig}>100;
    my $complen = 0;
    my $pl = 0;
    my $chr = 0;
    foreach my $triple (@{$finalmapping{$contig}}) {
	my $n = $triple->{"name"}; my $l = $triple->{"end"} - $triple->{"start"};
	if (defined $origout{$n}) {
	    $pl += $l*$origout{$n}{"pl"};
	    $chr += $l*$origout{$n}{"chr"};
	    $complen += $l;
	}   
    }

    $pl = $pl / $complen unless $complen == 0;
    $chr = $chr / $complen unless $complen == 0;

    print join(",",".",$contig,$contiglen{$contig},$pl,$chr,classify($pl,$chr)),"\n";  
}


sub classify {
    my ($pl,$chr) = @_;

    if ($pl > 0.5 && $chr > 0.5) {
	return "ambiguous";
    } elsif ($pl > 0.5) {
	return "plasmid";
    } elsif ($chr > 0.5) {
	return "chromosome";
    } else {
	return "unlabeled";
    }
}

sub overlaplen {
    my ($a,$b) = @_;

    my $x = min($a->{"end"},$b->{"end"})-max($a->{"start"},$b->{"start"});
    if ($x < 0) {
	return 0;
    } else {
	return $x;
    }
}

sub min {
    my ($a,$b) = @_;
    if ($a < $b) { return $a; } else { return $b; }
}

sub max {
    my ($a,$b) = @_;
    if ($a > $b) { return $a; } else { return $b; }
}


sub unify_file_format {
    my ($input,$output) = @_;

    my $gzipped = 0;
    my $format = "fasta";
    
    # detect file formats from the names
    if ( $input =~ /\.gz$/i ) {
	$gzipped = 1;
    }
    
    if ( $input =~ /\.gfa\.gz$/i || $input =~ /\.gfa/i ) {
	$format = "gfa";
    }

    my $command = "cat";
    if ($gzipped) {
	$command = "zcat";
    }

    my $fin; my $fout;
    open $fin,"$command $input |" or die "Cannot open file $input";
    open $fout,">$output" or die "Cannot open file $output";
    
    while (my $line = <$fin>) {
	chomp $line;
	if ( $format eq "fasta" ) {
	    # just copy the file
	    print $fout $line,"\n";
	} else {
	    # look for lines of the format S name sequence
	    next unless $line =~ /^S\s/;
	    my @parts = split "\t",$line;
	    print $fout ">",$parts[1],"\n";
	    print $fout $parts[2],"\n";
	}
    }
    close $fin;
    close $fout;
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
