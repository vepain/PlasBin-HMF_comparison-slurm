#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin); use lib "$Bin";  # include script directory in path

my $USAGE = "
$0 csv-file i j dbdir database list-of-assemblies

run rpsblast for the i..j row of the csv-file
csv-file - plasgraph2 list for training or testing 
dbdir - directory with the rpsblast database
database - name of the rpsblast database
list-of-assemblies - list of assemblies to process in each target directory
    ";

my $samplelist=shift or die $USAGE;
my $from=shift or die $USAGE;
my $to=shift or die $USAGE;
my $dbdir = shift or die $USAGE;
my $database = shift or die $USAGE;

open IN,"<$samplelist" or die;

my $row = 1;
my %targets;
while (my $line=<IN>) {
    if ($row >= $from && $row <= $to) {
	chomp $line;
	my @parts = split(",",$line);
	
	my $targetdir;
	
	if ($parts[0] =~ /^(.*)\/[^\/]+$/) {
	    $targetdir = $1;
	} else {
	    $targetdir = $parts[0];
	}
	
	print STDERR "$targetdir... ";
	if (-e "$targetdir/skesa-done") {
	    print STDERR "OK\n";
	    $targets{$targetdir}++;
	} else {
	    print STDERR "skip\n";
	}
    }

    $row++;
}

foreach my $targetdir (keys %targets) {
    foreach my $assembly (@ARGV) {
	if (-e "$targetdir/$assembly.gfa.gz") {
	    print "sbatch --time=0-3 -c 1 --mem=10G ";
	    print "/home/tvinar/projects/ctb-chauvec/tvinar/genomes/scripts/run-rpsblast.pl ";
	    print "$targetdir $assembly $dbdir $database\n";
	} else {
	    print STDERR "$targetdir/$assembly.gfa.gz does not exist!";
	}
    }
}

close IN;

