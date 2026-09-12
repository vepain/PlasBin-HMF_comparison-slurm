#! /usr/bin/perl -w
use strict;

my %sample;

my $samplesfname = shift or die;
my $samplesfile;
open $samplesfile,"<$samplesfname";

while (my $sampleid = <$samplesfile>) {
    chomp $sampleid;
    print STDERR $sampleid,"\n";
    $sample{$sampleid}{'sampleid'} = $sampleid;
    $sample{$sampleid}{'numshort'} = 0;
    $sample{$sampleid}{'numlong'} = 0;
    $sample{$sampleid}{'short'} = "";
    $sample{$sampleid}{'long'} = "";
    $sample{$sampleid}{'longtype'} = "";
    $sample{$sampleid}{'species'} = "";
    

    # find all associated sequencing runs on SRA
    print STDERR "esearch -db sra -query $sampleid | efetch -format runinfo |\n";
    my $in;
    open $in,"esearch -db sra -query $sampleid | efetch -format runinfo |";
    # parse header of runinfo
    my $header = <$in>;
    if (defined $header) {
	chomp $header;
	my @parts = split ",",$header;
	my %hi;
	for(my $i=0; $i < @parts; $i++) {
	    $hi{$parts[$i]} = $i;
	}
	
	while (my $line = <$in>) {
	    chomp $line;
	    @parts = split ",",$line;
	    my ($run,$date,$platform,$species) =
		($parts[$hi{'Run'}],$parts[$hi{'ReleaseDate'}],$parts[$hi{'Platform'}],$parts[$hi{'ScientificName'}]);

	    $sample{$sampleid}{'species'} = $species;
	    if ($platform eq "ILLUMINA") {
		$sample{$sampleid}{'short'} = $run;
		$sample{$sampleid}{'numshort'} += 1;
	    } elsif (($platform eq "OXFORD_NANOPORE") || ($platform eq "PACBIO_SMRT")) {
		$sample{$sampleid}{'long'} = $run;
		$sample{$sampleid}{'numlong'} += 1;
		$sample{$sampleid}{'longtype'} = $platform;
	    } else {
		warn "Unknown platform $platform";
	    }
	}
	
    }
    close $in;
    # avoid putting requests too fast
    sleep 1;
    print join("\t",$sample{$sampleid}{'species'},$sampleid,$sample{$sampleid}{'long'},
	       $sample{$sampleid}{'short'},$sample{$sampleid}{'longtype'},
	       $sample{$sampleid}{'numshort'},$sample{$sampleid}{'numlong'}),"\n";
}
close $samplesfile;
