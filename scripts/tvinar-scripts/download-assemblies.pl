#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin); use lib "$Bin";  # include script directory in path

my $USAGE = "
$0 csv-file
    ";

my $samplelist=shift or die $USAGE;


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
	die unless $parts[5] eq "assembly";
    } else {
	my $asm = $parts[5];
	my $target = $parts[0]."-".$parts[1]."/assembly.fasta.gz";
	print STDERR "$asm -> $target\n";
	unless (-e "$target" && -s "$target" > 0) {
	    # first try refseq
	    my $cmd = "esearch -db assembly -query $asm | ".
	    "elink -target nuccore -name assembly_nuccore_refseq | ".
	    "efetch -format fasta | gzip >$target";
	    my_run($cmd);
	    sleep(1);
	    if ( -s $target == 0) {
		# if there is no refseq, try genbank
		my $cmd = "esearch -db assembly -query $asm | ".
		    "elink -target nuccore -name assembly_nuccore_insdc | ".
		    "efetch -format fasta | gzip >$target";
		my_run($cmd);
		sleep(1);
	    }
	}
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
