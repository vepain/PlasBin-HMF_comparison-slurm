#! /usr/bin/perl -w
use strict;
use Getopt::Std;
use FindBin qw($Bin); use lib "$Bin"; 

my $USAGE = "
$0 assembly [reference_file.fasta.gz]

Run ground-truth-new.pl script for every subdirectory in the current directory.
assembly = for which assembly to compute ground truth

Options passed to ground-truth-new.pl:
-s similarity
-o output_suffix
    ";

my %Options;
getopts('s:o:',\%Options);

my $assembly = shift or die $USAGE;
my $reference = shift;


my $optstring = "";
$optstring.= " -s '".$Options{'s'}."'" if defined $Options{'s'};
$optstring.= " -o '".$Options{'o'}."'" if defined $Options{'o'};

my $parstring = $assembly;
$parstring.= " ".$reference if defined $reference;

open LIST,"ls */done |";
while (my $dir = <LIST>) {
    next unless $dir =~ /^(.*-.*)\/done$/;
    my $sample = $1;

    # guess the filename of the target
    my $target = "$sample/$assembly";
    if (defined $Options{'o'}) {
	$target .= ".".$Options{'o'};
    } else {
	$target .= ".gfa.csv";
    }
	
    print STDERR $sample," -> ",$target,"\n";
    my_run("$Bin/ground-truth-new-v2.pl $optstring $sample $parstring") unless (-e $target);
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
