#! /usr/bin/perl -w
use strict;
use Getopt::Std;
use FindBin qw($Bin); use lib "$Bin"; 

my $USAGE = "
$0 \"command\"

Run command for every subdirectory in the current directory.
    ";

die $USAGE unless @ARGV>0;

open LIST,"ls */done |";
while (my $dir = <LIST>) {
    next unless $dir =~ /^(.*-.*)\/done$/;
    my $sample = $1;
    my_run("cd $sample; ".join(" ",@ARGV));
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
