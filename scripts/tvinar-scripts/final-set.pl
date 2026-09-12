#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use File::Copy;
#use Data::Dumper;


my $usage = "
$0 input_data_path output_data_path set_file output_name

Gets a set file (e.g. sets/eskapee-train.csv) and a path to data.
It find every file in the set file, and copies it importnat files
needed for testing and training to a new dir using filenames created 
from the sample name. 

It creates directory called output_name within output_data_path
and also file output_name.csv which is a new set file.

E.g.:
./sampleprep/final-set.pl data ../sets sets/eskapee-train.csv eskapee-train

Output_data_path should exist, but dir for output_name within there should not.
    ";

die $usage unless @ARGV==4;
my ($input_data_path, $output_data_path, $set_file, $output_name) = @ARGV;
die "cannot find $input_data_path" unless -d $input_data_path;
die "cannot find $output_data_path" unless -d $output_data_path;
die "cannot find $set_file" unless -r $set_file;

my $out_dir = "$output_data_path/$output_name";
die "$out_dir already exists " if -r $out_dir;
mkdir $out_dir or die "cannot create $out_dir";

my $in;
open $in, "<", $set_file or die;
my $out;
open $out, ">", "$output_data_path/$output_name.csv" or die;
while(my $line = <$in>) {
    chomp $line;
    my @parts = split ",", $line;
    die unless @parts==3;
    
    my $old = "$input_data_path/$parts[0]";
    die "bad gfa.gz filename $old" unless $old =~ /\.gfa\.gz$/;
    die "cannot find $old" unless -r $old;
    my $new = "$out_dir/$parts[2].gfa.gz";
    print "cp $old $new\n";
    copy($old, $new) or die;

    my $old2 = "$input_data_path/$parts[1]";
    die "bad gfa.csv filename $old2" unless $old2 =~ /\.gfa\.csv$/;
    die "cannot find $old2" unless -r $old2;
    my $new2 = "$out_dir/$parts[2].gfa.csv";
    print "cp $old2 $new2\n";
    copy($old2, $new2) or die;

    print $out join(",", "$output_name/$parts[2].gfa.gz",
		    "$output_name/$parts[2].gfa.csv", $parts[2]), "\n";
}
close $in or die;
close $out or die;

    

