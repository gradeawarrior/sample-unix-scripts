#!/usr/bin/env perl
#
# Author: Peter Salas
# Contact: psalas@proofpoint.com
#
# Description:
#	syncronizes the contents of DIRECTORY1 to DIRECTORY2. By default, it will
#    	only tell you what files are out of sync. You will need to pass in the '-r'
#    	operation to actually perform the sync.
#

use strict;

my $argument;
my $argc = @ARGV; # Save the number of commandline parameters.
my $dir1;
my $dir2;
my $sync=0;
my $diff=0;
my @ignore_words = ();
my $change_bool=0;
my $change_count;
my @discrepancy = ();
my $error_code=0;


#################################
##### Retrieve Arguments ########
#################################


if ($argc<2) {
  usage();  # Call subroutine usage()
  exit(255);   # When usage() has completed execution,
            # exit the program.
} else {
  $dir1=shift;
  $dir2=shift;
  $argument=shift;
  
  # Remove trailing slash
  $dir1 =~ s/\/$//;
  $dir2 =~ s/\/$//;
  
  ## Check existence of directory variables
  if (not -e $dir1 and not -d $dir1) {
    print "[ERROR] '$dir1' does not exist or is not a directory\n\n";
    usage();
    exit(255);
  }
  if (not -e $dir2 and not -d $dir2) {
    print "[ERROR] '$dir2' does not exist or is not a directory\n\n";
    usage();
    exit(255);
  }
    
  while ($argument) {
	if ($argument eq "-r") {
	    $sync=1;
        } elsif ($argument eq "-i") {
	    my $ignore_file=shift;
	    if (-e $ignore_file) {
		@ignore_words = saveIgnoreWords($ignore_file);
	    } else {
		print STDERR "[ERROR] - IGNORE_FILE:'$ignore_file' does not exist!\n\n";
		usage();
		exit(255);
	    }
	} elsif ($argument =~ m/-diff/) {
	    $diff=1;
	} elsif ($argument eq "-h" or $argument =~ m/-help/i) {
            usage();
            exit(255);
        } else {			# Throw exception if unknown parameter
	    print STDERR "[ERROR] - Unknown argument '$argument'\n\n";
	    usage();
	    exit(255);
	}

	$argument=shift;
  } # End while loop
} # End condition

## Get list of files in directories
my @dir1_files=getFiles($dir1);
my @dir2_files=getFiles($dir2);

foreach my $file (@dir1_files) {
  ## Check if a Directory
  if (-d "$dir1/$file") {
    checkDirectory($file) if not isIgnoreWord($file);
  }
  elsif (-f "$dir1/$file") {
    checkFile($file) if not isIgnoreWord($file);
  }
}

if (not $change_bool) {
    print "Directories in-sync\n";
} else {
    print "There were $change_count changes\n";
}

## Verify no discrepancy
@discrepancy = checkDiscrepancy();
foreach my $discrepancy (@discrepancy) {
  print STDERR qq|[WARNING] Possible discrepancy found in dir:$dir2 file:$discrepancy\n|;
  $error_code=254;
}

## Exit nicely
$change_count = 253 unless $change_count <= 253;
exit($change_count) if not $error_code;
exit($error_code) if $error_code;


#################################
########### Functions ###########
#################################


sub usage {
    print <<EOF;
Usage: $0 DIRECTORY1 DIRECTORY2 [-r] [-diff] [-i IGNORE_LIST] [-h/--help]
    
INFORMATION:
        
    syncronizes the contents of DIRECTORY1 to DIRECTORY2. By default, it will
    only tell you what files are out of sync. You will need to pass in the '-r'
    operation to actually perform the sync.
        
DETAILS:

    DIRECTORY1          The assumed directory to sync against
    DIRECTORY2          The directory to sync
    -r                  Actually performs the synchronization operation.
    -diff		Performs a diff operation and displays output
    -i IGNORE_LIST      A file that contains a list of ignore words. This will
                        Do a regular expression check to ignore all files
                        containing those words.
    -h/--help           Prints this help
    
ERROR CODES:
    
    The following error codes were designed to help with automated tests
    
    254 > code > 0	Any positive number represents the number of changes
			performed. A possible problem is if there are more than
			253 changes, then the count will be wrong; it stops
			at 253.
			
    0			Script ran successfully and directories are in-sync
    
    254			If there is a discrepancy between Directory1 and
			Directory2. A discrepancy could be caused by the
			following:
			  - file in Directory2 is not a file, but a directory
			  - file in Directory2 is not a directory, but a file
			  - There are more files in Directory2 that are not in
			    Directory1
			
    255			If any of the following are true
			  - If there is a discrepancy between Directory1 and
			    Directory2
			  - The required number of parameters were not passed
			  - Directory1 is not a valid directory
			  - Directory2 is not a valid directory
			  - Ignore List is not a valid path to file
			  - This help message is displayed
			  - Invalid/Unknown parameter passed into script
    
EOF
}

sub saveIgnoreWords {
    my $ignore_file = shift;
    
    open FILE, "<$ignore_file" or die $!;
    my @ignore_words = <FILE>;
    close FILE;
    
    ## Cleanup of return carriage
    foreach (@ignore_words) {
        chomp($_);
    }
    
    return @ignore_words;
}

sub isIgnoreWord {
    my $file = shift;
    
    foreach my $word (@ignore_words) {
        if ($file =~ m/$word/) { return 1; }
    }
    return 0;
}

sub getFiles {
    my $directory = shift;
    my @files=split(m/\n/,`find $directory`);
    
    for (my $i=0; $i<@files; $i+=1) {
        $files[$i] =~ s/$directory\///;
        #print $files[$i], "\n";
    }
    shift @files;
    return @files;
}

sub checkDirectory {
  my $directory = shift;
  
  ## Print ERROR if file exists but it not a directory
  if (-e "$dir2/$directory" and not -d "$dir2/$directory") {
    print STDERR "[ERROR] $dir2/$directory was found, but was not a directory!\n";
    $error_code=254;
  
  ## Create Directory if it doesn't exist in Dir2
  } elsif (not -e "$dir2/$directory") {
    print ">> Create new $dir2/$directory\n";
    `mkdir $dir2/$directory` if $sync;
    addChange();
  }
  
  ## Update directory timestamp
  elsif ((-C "$dir1/$directory") < (-C "$dir2/$directory")) {
    print ">> $dir2/$directory is out of date\n";
    `touch $dir2/$directory` if $sync;
    addChange();
  }
}

sub checkFile {
  my $file = shift;
  my $diff_cmd = "diff $dir1/$file $dir2/$file";
  my $difference = -e "$dir2/$file" ? `$diff_cmd` : "";
  
  ## Print ERROR if file exists but it not a file
  if (-e "$dir2/$file" and not -f "$dir2/$file") {
    print STDERR "[ERROR] $dir2/$file was found, but was not a file!\n";
    $error_code=254;
  
  ## Create file if it doesn't exist in Dir2
  } elsif (not -e "$dir2/$file") {
    print ">> Create $dir2/$file\n";
    `cp $dir1/$file $dir2/$file` if $sync;
    addChange();
    
  ## Update file if file is different
  } elsif (((-C "$dir1/$file") < (-C "$dir2/$file")) and ($difference ne "")) {
    print ">> Updating $dir2/$file\n";
    
    ## Print diff
    if ($diff) {
      print "\$ $diff_cmd";
      print $difference,"\n";
    }
    
    `cp $dir1/$file $dir2/$file` if $sync;
    addChange();
  
  ## Touch file if file is out of date
  } elsif ((-C "$dir1/$file") < (-C "$dir2/$file")) {
    print ">> Touching $dir2/$file\n";
    `touch $dir2/$file` if $sync;
    addChange();
  }
}

sub checkDiscrepancy {
  my @files1 = getFiles($dir1);
  my @files2 = getFiles($dir2);
  my $i1 = 0;
  my $i2 = 0;
  my @discrepancy = ();
  
  while (($i1 < @files1) and ($i2 < @files2)) {
    #print qq|- $files1[$i1] == $files2[$i2] - |;
    if (isIgnoreWord($files1[$i1])) {
      #print "skipping $files1[$i1]\n";
      $i1 += 1;
    } elsif (isIgnoreWord($files2[$i2])) {
      #print "skipping $files2[$i2]\n";
      $i2 += 1;
    } elsif ($files1[$i1] eq $files2[$i2]) {
      #print "equal\n";
      $i1 += 1;
      $i2 += 1;
    } else {
      #print "notequal\n";
      push(@discrepancy, $files2[$i2]);
      $i2 += 1;
    }
  }
  
  return @discrepancy;
}

sub addChange {
    $change_bool=1;
    $change_count+=1;
}
