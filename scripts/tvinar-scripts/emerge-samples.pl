#! /usr/bin/perl -w
use strict;
use File::Basename;

my $sourcedir = "/home/tvinar/projects/ctb-chauvec/tvinar/genomes/plaseval";
my @filelist = qw/short.gfa.gz short.gfa.csv skesa.gfa.gz skesa.gfa.csv hybrid.gfa.gz hybrid.ref.csv plaseval-short.gfa.gz plaseval-short.gfa.csv plaseval-short.Pfam.tsv/;

my $usage = "
$0 sample-list

Copy samples from the sample source directory. The target will be
proper subdirectories of the current working directory.

source directory: $sourcedir
    ";

my $samplelist = shift or die $usage;

open IN,"<$samplelist";

while (my $line = <IN>) {
    chomp $line;
    my @parts = split ",",$line;
    emerge_file($parts[0]);
    emerge_file($parts[1]);
}

sub emerge_file {
    my ($file) = @_;

    return if (-e "$file");
    my $sample = dirname($file);

    print STDERR "Emerge sample $sample...\n";
    my_run("mkdir -p $sample");
    foreach my $f (@filelist) {
	if (-e "$sourcedir/$sample/$f") {
	    print STDERR "found $sourcedir/$sample/$f\n";
	    my_run("cp -p $sourcedir/$sample/$f $sample/$f");
	}
    }    
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

   
