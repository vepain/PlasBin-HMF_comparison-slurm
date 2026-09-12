#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin); use lib "$Bin";  # include script directory in path

my $USAGE = "
$0 csv-file i j

run single-sample for the i..j row of the csv-file
    ";

my $samplelist=shift or die $USAGE;
my $from=shift or die $USAGE;
my $to=shift or die $USAGE;

open IN,"<$samplelist" or die;
my $row = 0;
while (my $line=<IN>) {
    chomp $line;
    my @parts = split("\t",$line);

    if ($row == 0) {
	die unless $parts[0] eq "species_id";
	die unless $parts[1] eq "sample_id";
	die unless $parts[2] eq "long_reads";
	die unless $parts[3] eq "short_reads";
    }

    my $targetdir = "$parts[0]-$parts[1]";
    print STDERR "$targetdir...\n";
    next if (-e "$targetdir/skesa-done");


    if ($row >= $from && $row <= $to) {
	print "sbatch --time=1-0 -c 8 --mem=62G ";
        print "/home/tvinar/projects/ctb-chauvec/tvinar/genomes/scripts/single-sample.pl -r $parts[0] $parts[1] '$parts[3]' '$parts[2]'\n";
	print "sleep 10\n" if $row % 10 == 0;
    }

    $row++;
}

close IN;



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

