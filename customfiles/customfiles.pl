#!/usr/bin/perl -w

use Data::Dumper;

sub getdebfiles
{
	my $debinfo = "/var/lib/dpkg/info/";
	my %files = ();

	opendir(DIR, $debinfo);
	@files = grep { /.*list/ } readdir(DIR);
	foreach $file (@files)
	{
		open(FILE, $debinfo . $file);
		while (<FILE>) 
		{
			chomp;
			$files{$_} = 1;
		}
		close(FILE);
	}

	closedir(DIR);

	return %files;
}

sub getdebversions
{
	%files = ();

	open(FILE, "/var/lib/dpkg/diversions");
	while (<FILE>) 
	{
		chomp;
		$files{$_} = 1;
	}
	close(FILE);

	return %files;
}

# Get all the files in a directory except . + ..
sub checkfiles
{
	my $dir = shift;
	my $debfiles_ref = shift;
	my $debversions_ref = shift;
	my $ignores_ref = shift;
	my %debfiles = %$debfiles_ref;
	my %debversions = %$debversions_ref;
	my %ignores = %$ignores_ref;
	my @notreg = ();
	my $numreg = 0;
	my $file;
	my @files;

	# print "=== Checking ".$dir."\n";

	opendir(DIR, $dir);
	@files = readdir(DIR);
	closedir(DIR);

	foreach $file (@files)
	{
		next if ($file eq "." || $file eq "..");

		# Ignore it?
		if ($ignores{$dir.$file})
		{
			# Count them as registered though
			$numreg++;
			next;
		}

		# Descent when it is a directory
		if (-d $dir.$file)
		{
			# print "==== ".$dir.$file." is a directory, descending\n";

			# Does it have any registered files?
			my $nr = checkfiles($dir.$file."/", \%debfiles, \%debversions, \%ignores);
			if ($nr == 0)
			{
				# Is this file in debfiles?
				if ($debfiles{$dir.$file})
				{
					#print "==== ".$dir.$file." is a registered dir\n";
					# System file, thus can ignore it
					$numreg++;
					next;
				}
				else
				{
					push(@notreg, $file." [DIR]");
				}
			}
			else
			{
				$numreg += $nr;
			}

			next;
		}

		# print "==== ".$dir.$file." is a file, checking\n";

		# Is this file in debfiles?
		if ($debfiles{$dir.$file})
		{
			#print "==== ".$dir.$file." is a registered file\n";
			# System file, thus can ignore it
			$numreg++;
			next;
		}

		# Is it a debian diversion?
		next if ($debversions{$dir.$file});

		# Is the file a pre-compiled python file?
		next if ($file =~ /(.*)\.pyc/);

		# Is the file a symlink for an alternative?
		if (-l $dir.$file)
		{
			my $l = readlink($dir.$file);
			next if ($l =~ /\/etc\/alternatives\/(.*)/);
		}

		# Not registered
		#print "==== ".$dir.$file." is not registered\n";
		push(@notreg, $file);
	}

	# Did we have any registered files?
	# As then we can't just mark the whole directory as unregistered
	if ($numreg > 0)
	{
		# Show which files where not registered
		foreach $file (@notreg)
		{
			print $dir.$file."\n";
		}
	}

	return $numreg;
}

# Which files are registered?
my %debfiles = getdebfiles();
my %debversions = getdebversions();
my %ignores = ("/proc", 1, "/sys", 1, "/dev", 1, "/tmp", 1, "/var/cache/apt/archives", 1, "/run/", 1, "/var/lib/apt/lists/", 1);

# Loop through all the directories
# and figure out which files are missing
checkfiles("/", \%debfiles, \%debversions, \%ignores);

