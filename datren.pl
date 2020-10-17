use strict;
use warnings;
use Term::ProgressBar;
use Archive::Zip qw/:ERROR_CODES :CONSTANTS/;
use Digest::CRC qw(crc64 crc32 crc16 crcccitt crc crc8 crcopenpgparmor);

#init
my $substringrename = "-rename";
my $renameall = "FALSE";
my $datfile = "";
my $system = "";
my $discdirectory = "";
my $substringh = "-h";
my $bincue = "FALSE";
my $datbincue = "FALSE";
my @linesdat;
my @linesgames;
my @linesmatch;
my @linesmiss;
my @alllinesout;

#check command line
foreach my $argument (@ARGV) {
  if ($argument =~ /\Q$substringh\E/) {
    print "datren v0.5 - Utility to compare No-Intro or Redump dat files to the rom or disc collection\n";
    print "              and rename the matching files (by crc) to the dat standard.\n";
  	print "\n";
	print "with datren [ options ] [dat file ...] [directory ...] [system]\n";
	print "\n";
	print "Options:\n";
	print "  -rename  rename files with matching dat entries otherwise just log\n";
    print "\n";
	print "Example:\n";
	print '              datren -rename "D:/Atari - 2600.dat" "D:/Atari - 2600/Games" "Atari - 2600"' . "\n";
	print "\n";
	print "Author:\n";
	print "   Discord - Romeo#3620\n";
	print "\n";
    exit;
  }
  if ($argument =~ /\Q$substringrename\E/) {
    $renameall = "TRUE";
  }
}

#set paths and system variables
if (scalar(@ARGV) < 3 or scalar(@ARGV) > 4) {
  print "Invalid command line.. exit\n";
  print "use: datren -h\n";
  print "\n";
  exit;
}
$datfile = $ARGV[-3];
$system = $ARGV[-1];
$discdirectory = $ARGV[-2];

#debug
print "dat file: $datfile\n";
print "system: $system\n";
print "game directory: $discdirectory\n";
my $tempstr;
$tempstr = $renameall;
print "rename files: " . $tempstr . "\n";

#exit no parameters
if ($datfile eq "" or $system eq "" or $discdirectory eq "") {
  print "Invalid command line.. exit\n";
  print "use: datren -h\n";
  print "\n";
  exit;
}

#read dat file
open(FILE, "<", $datfile) or die "Could not open $datfile\n";
while (my $readline = <FILE>) {
   push(@linesdat, $readline);
   if (index(lc $readline, ".cue") != -1)
   {
      $datbincue = "TRUE";
   }
}
my @sorteddatfile = sort @linesdat;
close (FILE);

#read games directory contents
my $dirname = $discdirectory;
opendir(DIR, $dirname) or die "Could not open $dirname\n";
while (my $filename = readdir(DIR)) {
  if (-d $filename) {
    next;
  } else {
    push(@linesgames, $filename) unless $filename eq '.' or $filename eq '..';
	if (index(lc $filename, ".cue") != -1)
	{
       $bincue = "TRUE";
	}
  }
}
closedir(DIR);

my $romname = "";
my $gamename = "";
my $datcrc = "";
my $resultromstart;
my $resultromend;
my $resultgamestart;
my $resultgameend;
my $extpos;
my $extlen;
my $quotepos;
my $match = 0;
my $filecrc;
my $fileext;
my $totalmatches = 0;
my $totalmisses = 0;
my $totalmissesfiles = 0;
my $totalextrafiles = 0;
my $totalfuzzymatches = 0;
my $any_matched;
my $length = 0;
my $i=0;
my $j=0;
my $p=0;
my $q=0;

my @matches;
my @extrafiles;
my @sortedromenames;
my $max = scalar(@linesgames);
my $progress = Term::ProgressBar->new({name => 'progress', count => $max});

#loop though each filename
OUTER: foreach my $gameline (@linesgames)
{
   $progress->update($_);
   $p++;	
   
   #parse game name
   if (index(lc $gameline, ".m3u") == -1)
   {
      $match = 0;
      my $length = length($gameline);
      my $rightdot = rindex($gameline, ".");
      my $suffixlength = $length - $rightdot;
      $fileext = substr($gameline, $rightdot, $suffixlength);
      $gamename  = substr($gameline, 0, $length - $suffixlength);
	
      #calculate crc	
      open (my $fh, '<:raw', $discdirectory . "/" . $gameline) or die $!;
	  my $ctx = Digest::CRC->new( type => 'crc32' );
      $ctx->addfile(*$fh);
      close $fh;
      $filecrc = uc $ctx->hexdigest;
	
	  foreach my $datline (@sorteddatfile) 
      {
         if (index(lc $datline, "<rom name=") != -1)
         {
	        if (($datbincue eq "TRUE" and index(lc $datline, ".bin") == -1) or $datbincue eq "FALSE")
            {	  
		       #parse rom name
               $resultromstart = index($datline, '<rom name="');
               $resultromend = index($datline, 'size="');
               $extpos = rindex $datline, ".";  
               $quotepos = rindex $datline, '"', $resultromend;
               my $length = ($resultromend)  - ($resultromstart + 12);
               $romname  = substr($datline, $resultromstart + 11, $length - ($quotepos - $extpos + 1));
               $romname =~ s/amp;//g; #clean '&' in the dat file
         
		       #parse crc
		       $resultromstart = index($datline, 'crc="');
		       $resultromend = index($datline, 'md5="');
		       $length = ($resultromend)  - ($resultromstart + 6);
		       $datcrc = substr($datline, $resultromstart + 5, $length - 1);
		 		 
		       #push (@sortedromenames, [$romname, $datcrc]);        

               #check for exact match between dat crc and file crc
               if (uc $datcrc eq uc $filecrc)
               {
				  $match = 1;
                  $totalmatches++;
                  push(@linesmatch, [$gamename, $romname, $datcrc]);
				  push(@alllinesout, ["MATCHED: ", "$gamename to $romname crc: $datcrc"]);
		    
                  if ($renameall eq "TRUE")
                  {
                     rename($discdirectory . "/" . $gameline, $discdirectory . "/" . $romname . $fileext) || die ("Cannot rename: $gameline");
					 push(@alllinesout, ["RENAMED: ", "$gameline to $romname" . "$fileext"]);
                  }
                  next OUTER;
               }
            }
         }
      }
   }
}

#print total have
my $totalnames = 0;
$totalnames = $p;
print "\ntotal matches: $totalmatches of $totalnames\n";

#open log file and print all sorted output
open(LOG, ">", "$system.txt") or die "Could not open $system.txt\n";
print LOG "rename: " . $tempstr . "\n";
print LOG "total matches: $totalmatches of $totalnames\n";
print LOG "---------------------------------------\n";
my @sortedalllinesout = sort{$a->[1] cmp $b->[1]} @alllinesout;
for($i=0; $i<=$#sortedalllinesout; $i++)
{
  for($j=0; $j<2; $j++)
  {
    print LOG "$sortedalllinesout[$i][$j] ";
  }
  print LOG "\n";
}
close (LOG);

#print log filename
print "log file: $system.txt\n";
exit;