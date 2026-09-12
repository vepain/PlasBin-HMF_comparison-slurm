#! /usr/bin/perl -w
use strict;
use FindBin qw($Bin); use lib "$Bin";  # include script directory in path
use Getopt::Std;
use Cwd;

my $threads = 8;

my $usage = "
$0 [options] species sample short_sra long_sra

Options:
-r restart 
";

my %Options;
getopts('r',\%Options);

die $usage unless @ARGV==4;
my $species = shift;
my $sample = shift;
my $short = shift;
my $long = shift;


my ($dir,$tempdir) = dir_names("$species-$sample");
my $cwd = getcwd;

if (-e "$dir/done" && -e "$dir/skesa-done") {
    die "Already done!";
}


chdir($tempdir);

#download short reads
unless (-e "short_2.fastq.gz" && $Options{'r'}) {
    if ($short=~/\//) {
	my ($s1,$s2) = split(";",$short);
	my_run("cp $cwd/$s1 short_1.fastq.gz");
	my_run("cp $cwd/$s2 short_2.fastq.gz");
    } else {
	my_run("fastq-dump --gzip --split-files $short >>$dir/log");
	my_run("mv ${short}_1.fastq.gz short_1.fastq.gz");
	my_run("mv ${short}_2.fastq.gz short_2.fastq.gz");
    }
}

#download long reads
unless ((-e "long.fastq.gz" && $Options{'r'}) || -e "$dir/done") {
    if ($long =~ /\//) {
	my_run("cp $cwd/$long long.fastq.gz");
    } else {
	my_run("fastq-dump --gzip $long >>$dir/log");
	my_run("mv $long.fastq.gz long.fastq.gz");
    }
}

#unicycler short
unless ((-e "$dir/short.gfa" && $Options{'r'}) || -e "$dir/done") {
    my_run("unicycler -o short -1 short_1.fastq.gz -2 short_2.fastq.gz -t $threads --keep 0 2>&1 >>$dir/log");
    my_run("mv short/assembly.fasta $dir/short.fasta");
    my_run("mv short/assembly.gfa $dir/short.gfa");
    my_run("mv short/unicycler.log $dir/short.log");
}

#unicycler hybrid
unless ((-e "$dir/hybrid.gfa" && $Options{'r'}) || -e "$dir/done") {
    my_run("unicycler -o hybrid -1 short_1.fastq.gz -2 short_2.fastq.gz -l long.fastq.gz -t $threads --keep 0 2>&1 >>$dir/log");
    my_run("mv hybrid/assembly.fasta $dir/hybrid.fasta");
    my_run("mv hybrid/assembly.gfa $dir/hybrid.gfa");
    my_run("mv hybrid/unicycler.log $dir/hybrid.log");
}

#bwa
unless ((-e "$dir/short-aln.bw" && $Options{'r'}) || -e "$dir/done") {
    my_run("ln -fs $dir/short.fasta assembly.fasta");
    my_run("bwa index assembly.fasta 2>>$dir/log");
    my_run("bwa mem -t $threads assembly.fasta short_1.fastq.gz short_2.fastq.gz 2>>$dir/log | samtools view -S -b - |  samtools sort -  -o aln.bam");
    my_run("samtools index aln.bam");
    my_run("bedtools genomecov -ibam aln.bam -bga -split | sort -k1,1 -k2,2n > aln.bedgraph");
    my_run("faSize -detailed assembly.fasta > genome.sizes");
    my_run("bedGraphToBigWig aln.bedgraph genome.sizes $dir/short-aln.bw");
}

#short skesa assembly
unless ((-e "$dir/skesa.gfa" && $Options{'r'}) || -e "$dir/skesa-done") {
    my_run("skesa --reads short_1.fastq.gz,short_2.fastq.gz --cores $threads --min_contig 100 --contigs_out $dir/skesa.fasta 2>&1 >>$dir/log");
    my_run("gfa_connector --reads short_1.fastq.gz,short_2.fastq.gz --cores $threads --contigs $dir/skesa.fasta --gfa $dir/skesa.gfa 2>&1 >>$dir/log");
    # utils.py stuff now integrated in the main code so no need to run
}


#upracsiposebe
chdir($dir);
my_run("rm -rf temp");
my_run("gzip -f *.fasta *.gfa log");
my_run("touch done");
my_run("touch skesa-done");

sub dir_names {
    my ($query) = @_;
    my $res = $query;
    my $cwd = `pwd`; chomp($cwd);
    $res =~ s/\W+/-/g;
    $res = "$cwd/$res"; 
    my $restemp = "$res/temp";
    mkdir($res) unless (-d $res);
    mkdir("$res/temp") unless (-d $restemp);
    return ($res,$restemp);
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
