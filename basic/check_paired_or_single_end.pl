# See whether a fastq file is paired end or not. It must be in a velvet-style shuffled format.
# In other words, the left and right sides of a pair follow each other in the file.
# params: fastq file and settings
# fastq file can be gzip'd
# settings:  checkFirst is an integer to check the first X deflines
# TODO just extract IDs and send them to the other _sub()

print &is_fastqPE($ARGV[0])."\n";

###############################################################################################
sub is_fastqPE($;$){
  my($fastq,$settings)=@_;
 
  # if checkFirst is undef or 0, this will cause it to check at least the first 20 entries.
  # 20 reads is probably enough to make sure that it's shuffled (1/2^10 chance I'm wrong)
  $$settings{checkFirst}||=20;
  $$settings{checkFirst}=20 if($$settings{checkFirst}<2);
 
  # get the deflines
  my @defline;
  my $numEntries=0;
  my $i=0;
  my $fp;
  if($fastq=~/\.gz$/){
    open($fp,"gunzip -c '$fastq' |") or die "Could not open $fastq for reading: $!";
  }else{
    open($fp,"<",$fastq) or die "Could not open $fastq for reading: $!";
  }
  my $discard;
  while(my $defline=<$fp>){
    next if($i++ % 4 != 0);
    chomp($defline);
    $defline=~s/^@//;
    push(@defline,$defline);
    $numEntries++;
    last if($numEntries > $$settings{checkFirst});
  }
  close $fp;
 
  # it is paired end if it validates with any naming system
  my $is_pairedEnd=_is_fastqPESra(\@defline,$settings) || _is_fastqPECasava18(\@defline,$settings) || _is_fastqPECasava17(\@defline,$settings);
 
  return $is_pairedEnd;
}
sub _is_fastqPESra{
  my($defline,$settings)=@_;
  my @defline=@$defline; # don't overwrite $defline by mistake
 
  for(my $i=0;$i<@defline-1;$i++){
    my($genome,$info1,$info2)=split(/\s+/,$defline[$i]);
    if(!$info2){
      return 0;
    }
    my($instrument,$flowcellid,$lane,$x,$y,$X,$Y)=split(/:/,$info1);
    my($genome2,$info3,$info4)=split(/\s+/,$defline[$i+1]);
    my($instrument2,$flowcellid2,$lane2,$x2,$y2,$X2,$Y2)=split(/:/,$info3);
    $_||="" for($X,$Y,$X2,$Y2); # these variables might not be present
    if($instrument ne $instrument2 || $flowcellid ne $flowcellid2 || $lane ne $lane2 || $x ne $x2 || $y ne $y2 || $X ne $X2 || $Y ne $Y2){
      return 0;
    }
  }
  return 1;
}
 
sub _is_fastqPECasava18{
  my($defline,$settings)=@_;
  my @defline=@$defline;
 
  for(my $i=0;$i<@defline-1;$i++){
    my($instrument,$runid,$flowcellid,$lane,$tile,$x,$yandmember,$is_failedRead,$controlBits,$indexSequence)=split(/:/,$defline[$i]);
    my($y,$member)=split(/\s+/,$yandmember);
 
    my($inst2,$runid2,$fcid2,$lane2,$tile2,$x2,$yandmember2,$is_failedRead2,$controlBits2,$indexSequence2)=split(/:/,$defline[$i+1]);
    my($y2,$member2)=split(/\s+/,$yandmember2);
 
    # Instrument, etc must be the same.
    # The member should be different, usually "1" and "2"
    if($instrument ne $inst2 || $runid ne $runid2 || $flowcellid ne $fcid2 || $tile ne $tile2 || $member>=$member2){
      return 0;
    }
  }
  return 1;
}
# This format is basically whether the ends of the defline alternate 1 and 2.
sub _is_fastqPECasava17{
  my($defline,$settings)=@_;
  my @defline=@$defline;
  for(my $i=0;$i<@defline-1;$i++){
    # Get each member number but return false if it doesn't even exist.
    my ($member1,$member2);
    if($defline[$i] =~ m/(\d+)$/){
      $member1=$1;
    } else {
      return 0;
    }
    if($defline[$i+1] =~ /(\d+)$/){
      $member2=$1;
    } else {
      return 0;
    }
 
    # The test is whether member1 is less than member2.
    # They can't be equal either.
    if($member1 >= $member2){
      return 0;
    }
  }
 
  return 1;
}

