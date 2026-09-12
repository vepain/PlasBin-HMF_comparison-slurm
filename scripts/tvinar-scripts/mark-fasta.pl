#!/usr/bin/perl -w
use strict;

my $usage = "
$0 fasta-file add-to-headers [blacklist]

Add information to fasta headers in the fasta file.
The new fasta file is written to standard output.

Examples:
$0 reference.fa chromosome=true
$0 reference.fa plasmid=true
    ";

my $faname = shift or die $usage;
my $header = shift or die $usage;

my $blacklistfname = shift;

my %blacklist;

if (defined $blacklistfname) {
    open IN, "<$blacklistfname";
    while (my $s = <IN>) {
	chomp $s;
	$blacklist{$s}+=1;
    }
    close IN;
}


unless (-e "$faname") {
    die "File $faname does not exist!";
}

open IN,"<$faname";
my $passthru = 1;
while (my $line = <IN>) {
    chomp $line;
    if ($line =~ /^>\s*(\S+)\s*(.*)$/) {
	if ($blacklist{$1}) {
	    $passthru = 0;
	} else {
	    $passthru = 1;
	    print ">$1 $header $2\n";
	}
    } else {
	print $line,"\n" if $passthru;
    }
}
close IN;
