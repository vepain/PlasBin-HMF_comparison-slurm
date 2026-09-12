#! /usr/bin/perl -w
use strict;

my $usage = "
$0 sampledir assembly dbdir database

sampledir - directory with a sample
assembly - name of the assembly (hybrid,short,skesa,...)
dbdir - directory where database is located
database - directory and name of the database

for example:
https://ftp.ncbi.nlm.nih.gov/pub/mmdb/cdd/little_endian/Pfam_LE.tar.gz
unpack in dbdir
use Pfam as a database
    ";

my $dir = shift or die $usage;
my $assembly  = shift or die $usage;
my $dbdir = shift or die $usage;
my $database = shift or die $usage;

my $target = "$dir/$assembly.$database";
my $tempshortfa = "$dir/temp-short-$assembly.fasta";

die "$dir is not finished" unless (-e "$dir/done");
die "$dir is not finished" unless (-e "$dir/skesa-done");
# die "$dir already rpsblasted for $database" if (-e "$dir/rpsblast-$database-done");


gfa2fasta("$dir/$assembly.gfa.gz",$tempshortfa);
my_run("rpstblastn  -max_target_seqs 20000 -evalue 1e-3 -num_threads 1 ".
       "-db $dbdir/$database -query $tempshortfa -out $target.tmp ".
       "-outfmt \"6 qaccver qlen qstart qend saccver slen sstart send pident bitscore evalue stitle\"") unless (-e "$target.tmp");

open my $in,"<$target.tmp";
open my $out,">$target.tsv";
print $out join("\t", qw/score strand qName qLen qStart qEnd tName tLength tStart tEnd pIdent Evalue tDescription/),"\n";
close $out;

## this mildly disgusting piece of code was
## originally written by Brona as oneliner
open $out," | sort -k3,3 -k5g >> $target.tsv";
while (my $line = <$in>) {
    chomp $line;
    my @F = split "\t",$line;
    $F[6]--; my ($s,$e)=@F[2,3]; my $str=($s<=$e)?"+":"-";
    if ($str eq "-") { ($s,$e)=($e,$s); } $s--;
    print $out join("\t", $F[9], $str, @F[0,1],$s,$e,@F[4,5,6,7,8,10,11]),"\n";
}
close $out;

unlink($tempshortfa);
unlink("$target.tmp");
my_run("touch $dir/rpsblast-$database-done");

    
sub gfa2fasta
{
    my ($gfagz,$fa)=@_;
    print STDERR "Creating $fa from $gfagz...\n";
    
    my $in;
    my $out;
    
    open $in, "gunzip -c $gfagz |";
    open $out, "> $fa";
    
    while (my $line = <$in>) {
        next unless $line =~ /^S/;
        chomp $line;
        my @parts = split("\t",$line);
        my $name = $parts[1];
        my $seq = $parts[2];
        print $out ">$name length=",length($seq),"\n";
        print $out $seq,"\n";
    }

    close $in;
    close $out;
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
