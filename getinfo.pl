#! /usr/bin/perl

use warnings;
use Path::Class qw/file/;

my $filename = file(shift @ARGV);

#### Create a pet list with first name and last name and uuid
### my $filename = 'reag.txt';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
my $i=0;
my $rate="";
my $mean="";
my $median="";
my $ninefive="";
my $nini="";
my $threenine="";
my $maxl="";
my $t;

while (my $row = <$fh>) {
$_=$row;
/.*\:\s(\S+)\s.*/;
my $metric=$1;
## printf ("the info is %s\n",$metric);

##  if ($row =~ "SUCCESS" && $i==0) { $i=1; } ## This is the first entry to the file, flag we enter to the file.
if ($row =~ "rate" && $i==0)  {$i=1; $rate=$rate . ",$metric"; } ## Get the instance name
elsif ($row =~ "mean" && $i==1)  {$i=1; $mean=$mean . ",$metric";} ## Get the instance name
elsif ($row =~ "median" && $i==1)  {$i=1;$median=$median . ",$metric"; } ## Get the instance name
elsif ($row =~ "95th" && $i==1)  {$i=1; $ninefive=$ninefive . ",$metric";} ## Get the instance name
elsif ($row =~ "99th" && $i==1)  {$i=1; $nini=$nini . ",$metric";} ## Get the instance name
elsif ($row =~ "99.9th" && $i==1)  {$i=1; $threenine=$threenine . ",$metric"; } ## Get the instance name
elsif ($row =~ "max" && $i==1)  {$i=0; $maxl=$maxl . ",$metric"; } ## Get the instance name
else {$t=11;}
}

printf ("row rate $rate\n");
printf ("latency mean $mean\n");
printf ("latency median $median\n");
printf ("latency 95th percentile $ninefive\n");
printf ("latency 99th percentile $nini\n");
printf ("latency 99.9th percentile $threenine\n");
printf ("latency max $maxl\n");
