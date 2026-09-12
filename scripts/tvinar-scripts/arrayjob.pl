#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin); use lib "$Bin";  # include script directory in path

my $USAGE = "
$0 csv-file

run single-sample for the i-th row of the csv-file
i is set by an environmental variable SGE_TASK_ID
    ";

my $samplelist=shift or die $USAGE;
my $taskno=$ENV{'SGE_TASK_ID'};

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


    if ($row == $taskno) {
	my_run("$Bin/single-sample.pl $parts[0] $parts[1] $parts[3] $parts[2]")
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

