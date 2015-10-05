#!/usr/bin/env perl

# dnsspam calculator
# by Joost Vunderink (joost@carnique.nl)

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program (in docs/LICENSE); if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# perl is either in /usr/bin or in /usr/local/bin
# This env trick should run perl from either location.

# Read the documentation in docs/*.


#####################################################################
# Functions

sub Init;
sub ProcessArguments;

sub ReadConfigFile;
sub ReadHostFile;
sub ReadDatafiles;
sub ReadWordFiles;
sub ReadWordFile;
sub ReadRegexpFiles;
sub ReadRegexpFile;
sub ReadDomainFiles;
sub ReadDomainFile;

sub ExitWithHelp;

sub CalcSpamOfList;
sub CalcSpamValue;
sub CalcSpamValues;
sub CalcFieldPenalties;
sub CalcFieldPenalty;
sub CalcNumFieldPenalty;
sub CalcDomainPenalty;

sub AddToReport;
sub dprint;



#####################################################################
# Global vars

$check_words     = 1;
$check_regexps   = 1;
$check_numfields = 1;
$report = "";



#####################################################################
#
#   The main program
   
@hostlist = ();
Init();
ProcessArguments();
ReadHostFile();
ReadConfigFile();
ReadDatafiles();
$ret = CalcSpamValues(@hostlist);

# shells don't always like return values larger than 255
if ($ret > 255) {
  exit 255;
} elsif ($ret < 0) {
  exit 0;
} else {
  exit $ret;
}

#   End of main program
#
#####################################################################


#####################################################################
# Initialisation
sub Init
{
  $configfile = "/usr/local/etc/spamcalc.conf";
  $bare_output = 0;
  $datafilesdir = "";
  $debug = 0;
  $hostfile = "";
  $report = "";
  $showreport = 0;
  $version = "0.5";
}


#####################################################################
# Reading and processing of the command line arguments
sub ProcessArguments
{
  my $numargs = @ARGV;
  my $parse_ok = 1;
  
  dprint("Processing $numargs arguments\n", 2);

  if ($numargs == 0) {
    ExitWithHelp();
  }

  my $argument = shift(@ARGV);

  while($argument ne "") {
    if (($argument eq "-h")) { 
      ExitWithHelp();
    }
    elsif ($argument eq "-b") {
      $bare_output = 1;
    }
    elsif ($argument eq "-c") {
      $configfile = shift(@ARGV);
    }
    elsif ($argument eq "-d") {
      $debug = shift(@ARGV);
    }
    elsif ($argument eq "-f") {
      $hostfile = shift(@ARGV);
    }
    elsif ($argument eq "-v") {
      $showreport = 1;
    }
    else {
      push(@hostlist, $argument);
    }

    $argument = shift(@ARGV);
  }

  dprint("hostlist: @hostlist.\n", 2);
  $numhosts = @hostlist;
  if ($numhosts == 0 && $hostfile eq "") {
    ExitWithError("No hosts to calculate. Use -h for help.\n");
  }

  if ($parse_ok == 0) {
    ExitWithError("Argument error. Use -h for help.\n");
  }
}

#####################################################################
# Reading and processing of the main config file.
sub ReadConfigFile
{
  if (! -e $configfile) {
    ExitWithError("Config file not found. Use -h for help.\n");
  }

  open(CONFIGFILE, $configfile);
  @configlines = <CONFIGFILE>;
  chop(@configlines);

  foreach $configline(@configlines) {
    if ($configline =~ /^\s*datafilesdir\s*=\s*(.*)/ ) {
      dprint ("Datafilesdir is \"$1\".\n", 1);
      $datafilesdir = $1;
      $mwordfile   = $datafilesdir . "/words";
      $mregexpfile = $datafilesdir . "/regexps";
      $mdomainfile = $datafilesdir . "/domains";
    }
    
    if ($configline =~ /^\s*check_words\s*=\s*(.*)/ ) {
      dprint("Setting check_words to $1.\n", 2);
      $check_words = int($1);
    }
    
    if ($configline =~ /^\s*check_regexps\s*=\s*(.*)/ ) {
      dprint("Setting check_regexps to $1.\n", 2);
      $check_regexps = int($1);
    }

    if ($configline =~ /^\s*check_numfields\s*=\s*(.*)/ ) {
      dprint("Setting check_numfields to $1.\n", 2);
      $check_numfields = int($1);
    }
  }
}


#####################################################################
# Reads the list of hosts that need to be processed if -f <file> was
# specified on the command line
sub ReadHostFile
{
  if ($hostfile eq "") {
    return;
  }

  if (-e $hostfile)
  {
    open(HOSTFILE, $hostfile);
    @hostlist = <HOSTFILE>;
    chop(@hostlist); # get rid of trailing \n's
  }

  my $length = @hostlist;
  dprint("Hostlist length is $length.\n", 2);
  return @hostlist;
}


#####################################################################
# Reads all the datafiles with penalty scores.
sub ReadDatafiles
{
  ReadWordFiles();
  ReadRegexpFiles();
  ReadDomainFiles();
}


#####################################################################
# Reads the list of word files and then reads each word file.
sub ReadWordFiles
{
  if (! -e $mwordfile) {
    ExitWithError("Can't locate master word file $mwordfile; is your config file correct?\n");
  }
  open(MWORDFILE, $mwordfile);
 
  my @mwordlines = <MWORDFILE>;
  my $nummwordlines = @mwordlines;
  my $mwordline;
  my $subdir = "";
  dprint ("Opening master spamword file $mwordfile with $nummwordlines lines...\n", 1);

  # First check if a subdir is used
  foreach $mwordline (@mwordlines) {
    if ($mwordline =~ /^\s*subdir\s*=\s*([^\s]+)\s*/) {
      dprint("Subdir \"$1\" for words found.\n", 2);
      $subdir = $1;
    }
  }

  # Now read all the spamword datafile names and read the files
  foreach $mwordline (@mwordlines) {
    $mwordline =~ s/#.*//;
    $mwordline =~ s/^\s+|\s+$//;
    if ($mwordline ne "" && $mwordline !~ /^\s*subdir\s*=.*/) {
      dprint("Reading sub word file \"$mwordline\".\n", 1);
      if ($subdir eq "") {
        ReadWordFile($datafilesdir . "/" . $mwordline);
      } else {
        ReadWordFile($datafilesdir . "/" . $subdir . "/" . $mwordline);
      }
    }
  }
}


#####################################################################
# Reads all spamwords with value from a single file
sub ReadWordFile
{
  my ($wordfile) = @_;
  if (! -e $wordfile) {
    print STDERR ("Wordfile $wordfile does not exist.\n");
    return;
  }
  open(WORDFILE, $wordfile);
  @wordlines = <WORDFILE>;
  $numwordlines = @wordlines;
  if ($numwordlines == 0) {
    print STDERR ("Wordfile $wordfile is empty.\n");
    return;
  }

  dprint("Read spamwords file $wordfile with $numwordlines lines.\n", 2);
  foreach $wordline (@wordlines)
  {
    # remove excess spaces, and everything including and right of a #
    $wordline =~ tr/A-Z/a-z/;
    $wordline =~ s/#.*//;
    $wordline =~ s/^\s+|\s+$//;
    # match <word><spaces><number>
    # spaces in front are ignored
    if ($wordline =~ /\s*([a-z\d]+)\s+(\d+)/ )
    {
      $wordvalue{$1} = $2;
      dprint("Added spamword $1 with penalty $2.\n", 2);
    }
    # negative spam values
    if ($wordline =~ /\s*([a-z\d]+)\s+(-\d+)/ )
    {
      $wordvalue{$1} = $2;
      dprint("Added spamword $1 with penalty $2.\n", 2);
    }
  }
}

#####################################################################
# Reads the list of regexp files and then reads each regexp file.
sub ReadRegexpFiles
{
  if (! -e $mregexpfile) {
    ExitWithError("Can't locate master regexp file $mregexpfile; is your config file correct?\n");
  }
  open(MREGEXPFILE, $mregexpfile);
 
  my @mregexplines = <MREGEXPFILE>;
  my $nummregexplines = @mregexplines;
  my $mregexpline;
  my $subdir = "";
  dprint ("Opening master regexp file $mregexpfile with $nummregexplines lines...\n", 1);

  # First check if a subdir is used
  foreach $mregexpline (@mregexplines) {
    if ($mregexpline =~ /^\s*subdir\s*=\s*([^\s]+)\s*/) {
      dprint("Subdir \"$1\" for regexps found.\n", 2);
      $subdir = $1;
    }
  }

  # Now read all the regexp datafile names and read the files
  foreach $mregexpline (@mregexplines) {
    $mregexpline =~ s/#.*//;
    $mregexpline =~ s/^\s+|\s+$//;
    if ($mregexpline ne "" && $mregexpline !~ /^\s*subdir\s*=.*/) {
      dprint("Reading sub regexp file \"$mregexpline\".\n", 1);
      if ($subdir eq "") {
        ReadRegexpFile($datafilesdir . "/" . $mregexpline);
      } else {
        ReadRegexpFile($datafilesdir . "/" . $subdir . "/" . $mregexpline);
      }
    }
  }
}


#####################################################################
# Reads all spam regexps with value from a single file
sub ReadRegexpFile
{
  my ($regexpfile) = @_;
  
  if (! -e $regexpfile) {
    print STDERR ("Regexpfile $regexpfile does not exist.\n");
    return;
  }

  open(REGEXPFILE, $regexpfile);
  @regexplines = <REGEXPFILE>;
  $numregexplines = @regexplines;
  
  dprint("Read regexps file $regexpfile with $numregexplines lines.\n", 2);

  if ($numregexplines == 0) {
    print STDERR ("Regexpfile $regexpfile is empty.\n");
    return;
  }

  foreach $regexpline (@regexplines)
  {
    # remove excess spaces, and everything including and right of a #
    $regexpline =~ s/#.*//;
    $regexpline =~ s/^\s+|\s+$//;
    # match <regexp><spaces><number>
    # spaces in front are ignored
    if ($regexpline =~ /\s*([^\s]+)\s+(\d+)/ )
    {
      $regexpvalue{$1} = $2;
      #dprint STDERR ("Added spamregexp $1 with penalty $2.\n", 2);
    }
    #negative regexp
    if ($regexpline =~ /\s*([^\s]+)\s+(-\d+)/ )
    {
      $regexpvalue{$1} = $2;
      #dprint STDERR ("Added spamregexp $1 with penalty $2.\n", 2);
    }

  }
}

#####################################################################
# Reads the list of domain files and then reads each domain file.
sub ReadDomainFiles
{
  if (! -e $mdomainfile) {
    ExitWithError("Can't locate master domain file $mdomainfile; is your config file correct?\n");
  }
  open(MDOMAINFILE, $mdomainfile);
 
  my @mdomainlines = <MDOMAINFILE>;
  my $nummdomainlines = @mdomainlines;
  my $mdomainline;
  my $subdir = "";
  dprint ("Opening master domain file $mdomainfile with $nummdomainlines lines...\n", 1);

  # First check if a subdir is used
  foreach $mdomainline (@mdomainlines) {
    if ($mdomainline =~ /^\s*subdir\s*=\s*([^\s]+)\s*/) {
      dprint("Subdir \"$1\" for domains found.\n", 2);
      $subdir = $1;
    }
  }

  # Now read all the spamword datafile names and read the files
  foreach $mdomainline (@mdomainlines) {
    $mdomainline =~ s/#.*//;
    $mdomainline =~ s/^\s+|\s+$//;
    if ($mdomainline ne "" && $mdomainline !~ /^\s*subdir\s*=.*/) {
      dprint("Reading sub domain file \"$mdomainline\".\n", 1);
      if ($subdir eq "") {
        ReadDomainFile($datafilesdir . "/" . $mdomainline);
      } else {
        ReadDomainFile($datafilesdir . "/" . $subdir . "/" . $mdomainline);
      }
    }
  }
}


#####################################################################
# Reads all domains with value from a single file
sub ReadDomainFile
{
  my ($domainfile) = @_;
  if (! -e $domainfile) {
    print STDERR ("Domains file $domainfile does not exist.\n");
    return;
  }
  open(DOMAINFILE, $domainfile);
  @domainlines = <DOMAINFILE>;
  $numdomainlines = @domainlines;
  if ($numdomainlines == 0) {
    print STDERR ("Domains file $domainfile is empty.\n");
    return;
  }

  dprint("Read domains file $domainfile with $numdomainlines lines.\n", 2);
  foreach $domainline (@domainlines)
  {
    # remove excess spaces, and everything including and right of a #
    $domainline =~ tr/A-Z/a-z/;
    $domainline =~ s/#.*//;
    $domainline =~ s/^\s+|\s+$//;
    # match <word><spaces><number>
    # spaces in front are ignored
    if ($domainline =~ /\s*([^\s]+)\s+(\d+)/ )
    {
      $domainvalue{$1} = $2;
      dprint("Added domain $1 with base value $2.\n", 2);
    }
    # negative spam values
    if ($domainline =~ /\s*([^\s]+)\s+(-\d+)/ )
    {
      $domainvalue{$1} = $2;
      dprint("Added domain $1 with base value $2.\n", 2);
    }
  }
}



#####################################################################
# calculates spam value of a list of hosts
sub CalcSpamValues
{
  my (@hostlist) = @_;
  my $spamvalue;
  my $hostlistlength = @hostlist;
  
  # bare output is only useful when processing 1 hostname
  #if ($hostlistlength > 1) {
  #  bare_output = 0;
  #}
  
  foreach $host(@hostlist)
  {
    $host =~ s/^\s+|\s+$//;
    if ($host ne "")
    {
      $report = "";
      $spamvalue = CalcSpamValue($host);
      if ($bare_output) {
        printf("%d", $spamvalue);
      } else {
        if ($showreport) {
	  printf("$host\n${report}Total of $spamvalue for $host.\n\n");
	}
	else {
          printf("%3d - $host\n", $spamvalue);
	}
      }
    }
  }

  $hostlistlength = @hostlist;
  if ($hostlistlength > 1)
  {
    print("Processed $hostlistlength hostnames.\n");
  }

  return $spamvalue;
}


#####################################################################
# calculates spam value of one host
sub CalcSpamValue
{
  my ($host, $report) = @_;
  $report = "";
  $host =~ tr/A-Z/a-z/;
  $sv = 0;
  $sv += CalcDomainPenalty($host);
  $sv += CalcFieldPenalties($host);
  $sv += CalcNumFieldPenalty($host);
  return $sv;
}


#####################################################################
# check each field for spam
sub CalcFieldPenalties
{
  my ($host) = @_;
  my $fieldvalue = 0;
  @hostfields = split(/\./, $host);
  
  # ignore the country code and the first domain
  $numfields = @hostfields;
  @hostfields_no_tld = @hostfields[0..$numfields-3];
    
  foreach $hostpart (@hostfields_no_tld)
  {
    if (defined $wordvalue{$hostpart} && $check_words == 1) {
      $fieldvalue += $wordvalue{$hostpart};
      AddToReport("\"$hostpart\" via wordmatch", $wordvalue{$hostpart});
    }
    elsif ($check_regexps)
    {
      # check in the list of regexps if this word is matched
      # only do this if there has been no direct match from the spamwords
      @regexplist = keys %regexpvalue;
      $regexplistlength = @regexplist;
      foreach $spamregexp (@regexplist) {
        if ($hostpart =~ /$spamregexp/) {
          $fieldvalue += $regexpvalue{$spamregexp};
          AddToReport("\"$hostpart\" via regexpmatch of $spamregexp", $regexpvalue{$spamregexp});
        }
      }
    }
  }

  return $fieldvalue;
}


#####################################################################
sub CalcNumFieldPenalty
{
  my ($host) = @_;
  my $pen = 0;

  @hostfields = split(/\./, $host);
  $numfields = @hostfields;

  dprint("Calculating number of fields penalty for $numfields fields.\n", 1);
  if ($numfields == 5) { $pen = 5; } 
  if ($numfields == 6) { $pen = 14; } 
  if ($numfields == 7) { $pen = 35; } 
  if ($numfields == 8) { $pen = 68; } 
  if ($numfields > 8)  { $pen = 15 + ($numfields - 3) * ($numfields - 3) * ($numfields - 3); }
  
  AddToReport("containing $numfields fields", $pen);
  return $pen;
}

#####################################################################
sub CalcDomainPenalty
{
  my ($host) = @_;
  my $pen = 0;
  my @domains = keys(%domainvalue);

  foreach $domain (@domains) {
    $pattern = "${domain}\$";
    $pattern =~ s/\./\\\./; #replace "." by "\."
    if ($host =~ /$pattern/) {
      $pen = $domainvalue{$domain};
      dprint("Adding $pen points for domain $domain.\n", 1);
      AddToReport("being in the domain $domain", $pen);
      return $pen;
    }
  }

  return 0;
}


#####################################################################
sub AddToReport
{
  my ($text, $value) = @_;
  if ($value > 0) {
    $report = $report . "Added " . $value . " points for " . $text . ".\n";
  } elsif ($value < 0) {
    $value =~ s/-//; # remove the minus
    $report = $report . "Subtracted " . $value . " points for " . $text . ".\n";
  } else {
    $report = $report . "No points for " . $text . ".\n";
  }

  return;
}

#####################################################################
# Debug Print function. Prints $text if the debug level is higher than the
# required level.
sub dprint
{
  my ($text, $level) = @_;
  if ($debug > $level)
  {
    print STDERR ("$text");
  }
}


#####################################################################
sub ExitWithHelp
{
  print("$0, a dnsspam calculator. version $version\n");
  print("Usage: $0 [OPTION]... hostname\n");
  print("Options:\n");
  print(" -b                    Bare output: only the penalty value.\n");
  print(" -c configfile         Uses this file for penalties\n");
  print(" -d <value>            Debug level. Use 0-5 for value.\n");
  print(" -f hostfile           Read all hostnames in this file.\n");
  print(" -v                    Turn on verbose mode.\n");
#  print(" -s [score|name]       Sort output by either score or name.\n");
#  print(" -t <value>            Return value is 1 if spamscore >= value,\n");
#  print("                       and otherwise 0.\n");
  print("Read the file 'docs/arguments' for a more detailed description of the options.\n");
exit(0);
}

#####################################################################
sub ExitWithError
{
  my ($error) = @_;
  print("$error\n");
  exit(0);
}
