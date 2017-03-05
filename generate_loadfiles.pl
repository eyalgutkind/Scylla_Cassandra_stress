#! /usr/bin/perl

use warnings;
use Path::Class qw/file/;
use Time::localtime;
my $tm = localtime;
my $mydate=join "",$tm->mday,($tm->mon)+1,$tm->year+1900;
my $num_args = $#ARGV + 1;
if ($num_args != 6) {
    print "\nUsage: generate_loadfiles.pl [outputfilenames prefix] [ansible host file] [loaders header ini file] [hosts' user name] [# of write transaction per loader] [C\*\/Scylla servers IPs]\n";
    print "Example: generate_loadfiles.pl i2xlarge_scylla1.6 scyllatest.ini loaders centos 11600000 172.10.1.4,172.10.1.5,172.10.1.6\n\n";
    print "All fileds are mandatory. The script will generate all the executable files to complete Cassandra stress testing\n";
    print "To complete the execution of the tests you will use ansible in ad-hoc mode (command line) \n";
    print "Your ansible host file should have entries similar to the below example\n";
    print "[loaders]\n";
    print "54.3.2.1\n";
    print "54.3.2.2\n";
    print "54.3.2.3\n";
    print "[servers]\n";
    print "54.3.3.9\n";
    print "54.3.3.10\n";
    print "54.3.3.11\n";

    exit;
}

my $filename = $ARGV[0];  ## This is the header name file
my $ansiblefile =  $ARGV[1]; ## The ansible file will provide the number of loaders you'll be using
my $ansibleloadersname = $ARGV[2]; ## The ansible ini file loaders header
my $loaderuser = $ARGV[3]; ## The user name to be used in the loader machines, for example, centos or root
my $numofrecs = $ARGV[4]; ## Number of write transactions requested per loader
my $serverips = $ARGV[5]; ## The Scylla or Cassandra Servers IPs
my $totalloaders=0; # We will get the number of loaders from ansible ini file
my $i=0;
my $lastinrng=0;
my @loadersip=();
my $filecnt=1;

my $writeoutfile = join "_", "testwrite", $mydate, $filename;
my $readsmalloutfile = join "_", "testreadsmall", $mydate, $filename;
my $readlargeoutfile = join "_", "testreadlarge", $mydate, $filename;


my $OUTFILE;
my $ANSFILE;
$i=0;
open(my $ANSIBLE, '<:encoding(UTF-8)', $ansiblefile)
  or die "Could not open file '$ansiblefile' $!";
while (my $row = <$ANSIBLE>) {
$_=$row;
s/\[//;s/\]//;s/\n//;
$row=$_;
if ($row eq $ansibleloadersname && $i==0)  {$i=1;$totalloaders=0; } ## Start getting loaders info
elsif ($i==1 && $row eq "") {$i=0;}  ## Finished getting loaders info
elsif ($i==1) {$totalloaders++;$_=$row; s/\n//; push @loadersip,$_;} #get loader IP address 
}

my $totalpartitions = $numofrecs*$totalloaders; # Calculate the number of total partitions to be written


for ($i=1;$i<$totalpartitions;$i+=$numofrecs)
{
$lastinrng=$lastinrng+$numofrecs; 
my $outfiles="writestress_$filecnt";
open $OUTFILE, '>', $outfiles;
print { $OUTFILE } "\#\!\/bin\/sh\n\n";
print { $OUTFILE } ("nohup cassandra-stress write n=$numofrecs cl=QUORUM -schema \"replication\(factor=3\)\" -mode native cql3 -pop seq=$i..$lastinrng -node $serverips -rate threads=500 -log file=$writeoutfile\n");
close $OUTFILE;
$filecnt++;
}

my $readlargesh = join ".", "readlarge", $mydate, "sh";
my $halfpart=int($totalpartitions/2);
my $stefevgause=int($halfpart/3);
open $OUTFILE, '>', $readlargesh;
print { $OUTFILE } "\#\!\/bin\/sh\n\n";
print { $OUTFILE } ("nohup cassandra-stress read duration=60m cl=QUORUM -mode native cql3 -pop dist=gaussian\\(1..$totalpartitions,$halfpart,$stefevgause\\) -node $serverips     -rate threads=500 -log file=$readlargeoutfile\n");
 close $OUTFILE;


my $readsmallsh = join ".", "readsmall", $mydate, "sh";
open $OUTFILE, '>', $readsmallsh;
print { $OUTFILE } "\#\!\/bin\/sh\n\n";
print { $OUTFILE } ("nohup cassandra-stress read duration=60m cl=QUORUM -mode native cql3 -pop dist=gaussian\\(1..$totalpartitions,$halfpart,100\\) -node $serverips     -rate threads=500 -log file=$readsmalloutfile\n");
 close $OUTFILE;


my $writetest = join ".", "writetest", $mydate, "sh";
### This script assumes the user name for the instances you are using is centos, if the name is different, please change the name in the next line accordingly
my $user="centos";
my $outfiles="loadersfiles.sh";
open $OUTFILE, '>', $outfiles;
for ($i=1;$i<=$totalloaders;$i++) {
my $currentip = pop @loadersip;
print {$OUTFILE} ("scp -i ~/.ssh/id_rsa writestress_$i $user\@$currentip:~/$writetest\n");
print {$OUTFILE} ("scp -i ~/.ssh/id_rsa $readlargesh $user\@$currentip:~/$readlargesh\n");
print {$OUTFILE} ("scp -i ~/.ssh/id_rsa $readsmallsh $user\@$currentip:~/$readsmallsh\n");
}


######## What's next section
printf (" Dear Benchmark creator! \n");
printf (" You have now created the loader files, the small and large read files.\n");
printf (" The next step is to copy them to your loaders. Make sure you have defined correctly ssh key\n");
printf (" And changed the user from centos to your user name in the loaders \n");
printf (" To send the files to the loaders, copy and past the following command to you command line shell\n");
printf (" source loadersfiles.sh \n");
printf (" using ansible ad-hoc command, change the files attributes to be exectuables\n");
printf (" ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a \"sudo chmod 777 $writetest\" \n");
printf (" ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a \"sudo chmod 777 $readlargesh\" \n");
printf (" ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a \"sudo chmod 777 $readsmallsh\" \n");

printf (" To execute the tests, use the ansible ad-hoc commands and wait for complition \n");
printf (" For example: \n");
printf (" ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a \"./$readsmallsh\" \n");

printf (" To collect the information from the loaders use, again, the ansible ad-hoc command: \n");
printf (" ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a \"tail -16 $readsmalloutfile\" \> myresults.txt \n");
printf (" Use the script, getinfo.pl to extract the results in csv format, for example\: \n");
printf (" \.\/getinfo.pl  myresults.txt \n"); 
printf (" row rate ,65759,63675,65272 \n");
printf (" latency mean ,7.6,7.8,7.6 \n");
printf (" latency median ,3.2,3.4,3.2 \n");
printf (" latency 95th percentile ,5.7,6.0,5.7 \n");
printf (" latency 99th percentile ,18.1,15.9,13.4 \n");
printf (" latency 99.9th percentile ,386.9,387.0,385.8 \n");
printf (" latency max ,896.1,921.7,851.8 \n");
 




