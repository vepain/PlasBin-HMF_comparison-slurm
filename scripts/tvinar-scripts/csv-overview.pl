#! /usr/bin/perl -w
use strict;

my $minlen = 101;

my @labels = ("chromosome","plasmid","ambiguous","unlabeled");

print "";
foreach my $csv (@ARGV) {
    foreach my $l (@labels) {
	my $ll = substr($csv,0,2)." ".substr($l,0,2);
	print "\t$ll #\t$ll kbp";
    }
}
print "\n";

my $list;
open $list,"ls */done |";
while (my $d = <$list>) {
    next unless $d =~ /^(.*-.*)\/done$/;
    my $dir = $1;

    print $dir;

    foreach my $csv (@ARGV) {
	my %num;
	my %len;

	foreach my $l (@labels) {
	    $num{$l} = 0;
	    $len{$l} = 0;
	}
    
	my $row = 0;
	
	my $in;
	open $in, "< $dir/$csv";
	while (my $line = <$in>) {
	    chomp $line;
	    my @parts = split ",",$line;
	    
	    if ($row == 0) {
		die unless $parts[3] eq "label";
		die unless $parts[4] eq "length";
	    } else {
		if ($parts[4]>=$minlen) { 
		    $num{$parts[3]} += 1;
		    $len{$parts[3]} += $parts[4];
		}
	    }
	    $row += 1;
	}
	
	close $in;

	foreach my $l (@labels) {
	    print "\t",$num{$l},"\t",sprintf('%.02f',(0.0+$len{$l})/1000);
	}
    }	
    print "\n";
}    

close $list;
    
