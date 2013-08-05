#!/usr/bin/perl -w
#
# lwang: This is a wrapper around cfg2 for the release team
#
#
# 0. cd $HOME   OR warn: run this scr in home dir
# 1. /usr/local/foobar/bin/cfg2 init -b BR_REL_1130 -s twitter-sync 1130
# 1.1.  cd to BR_REL_1130
# 2. /usr/local/foobar/bin/cfg2 check -s twitter-sync -a 0.0.1130-RC1.7164
# 3. /usr/local/foobar/bin/cfg2 publish -f PROD-ELA4,PROD-ECH3 -s twitter-sync -a 0.0.1130-RC1.7164 -p
#
#  556  cfg2 init -b BR_REL_1130 -s auth-server 1130
#  557  cd BR_REL_1130/
#  558  cfg2 check -s auth-server -a 0.0.1128-RC2.7304
#  559  cfg2 publish -f STG-BETA -s auth-server -a 0.0.1128-RC2.7304 
#
# 
#
#rotozip.corp:lwang[593] ~/code/itops/glu/bin $ ./gen_manif_from_glu.rb   -e beta  --getwar leo-tomcat  --nosvn
#leo-war
#rotozip.corp:lwang[594] ~/code/itops/glu/bin $ ./gen_manif_from_glu.rb   -e beta  --getwar auth-server --nosvn
#security-auth-war
#
#
use strict;
use Getopt::Long;
use Cwd;

# set autoflush
$| = 1;

################### ugly globals
my @failed_apps;  # report failed apps at the end 
my $cfg2 = "/usr/local/foobar/bin/cfg2";

chomp(my $home_dir = $ENV{HOME} );

# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});

# need RELREPO_HOME to get RELEASE.BOM
die "Please have your RELREPO environment variable set and point it to a checked-out workspace of relrepo.\n" unless $ENV{RELREPO};
chomp(my $relrepo =  $ENV{RELREPO});

my $getwar_scr = "$itops_home/glu/bin/gen_manif_from_glu.rb";

use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use Utils qw( array_unique );


my $release;
my $file;
my $service;
my $fabrics;
my $verbose;
my $check;     # if check is required explicitly
my $publish;   # publish in prod area
my $help;
my $debug;

GetOptions(
	"release=s"                            => \$release,
	"service=s"                            => \$service,
	"file=s"                               => \$file,
	"fabrics|f=s"                          => \$fabrics,
	"help"                                 => \$help,
	"debug"                                => \$debug,
	"verbose"                              => \$verbose,
	"publish"                              => \$publish,
	"check"                                => \$check,
);

my $usage =<<USAGE;

usage: $0 { -r | --release <release> } 
          { { -s | --service <service> } | {  -fi | --file <file_containing_services>  } } 
          { -f | --fabrics <comma_separated_fabric_names> } 
          [ -c | --check ]
          [ -p | --publish ]
          [ -h | --help ] 
          [ -v | --verbose ] 
          [ -d | --debug ] 

where:
	- release: release name, e.g., R1130
	- service: service  name, e.g., twitter-sync   [ NOTES: container name actually... what a mess! ] 
	- file: filename containing a list of services for checking
	- fabrics: e.g., PROD-ELA4,PROD-ECH3  or STG-BETA

notes:
	- release name is required
	- service or file required
	- fabrics  required

examples:
	1)
	$0 -v -r R1130 -s twitter-sync -f PROD-ELA4,PROD-ECH3 
		: This will check configs of twitter-sync in R1130 for PROD-ELA4 and PROD-ECH3, and publish locally.

	2)
	$0 -v -r R1130 -s twitter-sync -f PROD-ELA4,PROD-ECH3  --check
		: This will check configs of twitter-sync in R1130 for PROD-ELA4 and PROD-ECH3, and publish locally, with explicit cfg2 check.

	3)
	$0 -v -r R1130 -s twitter-sync -f PROD-ELA4,PROD-ECH3 -p
		: This will check configs of twitter-sync in R1130 for PROD-ELA4 and PROD-ECH3, and publish in PROD area.

	4)
	$0 -v -r R1130  -f PROD-ELA4,PROD-ECH3  --file ./foobar
		: This will check configs of apps in ./foobar in R1130 for PROD-ELA4 and PROD-ECH3, and publish locally.


USAGE


if ( $help ) {

  print $usage; exit;

}

unless ( $release ) {

  print "--service required.\n";
  print $usage; exit;

}

unless (  ( $service or $file ) and $fabrics ) {  

  print "--service and --fabrics or --file and --fabrics are required.\n";
  print $usage; exit;

}

if ( $service and $file ) {

  print "--service and --file are mutually exclusive.\n";
  print $usage; exit;

}

$release = uc $release; # in case ....

if ( $debug ) {
  print "[DEBUG] release: $release\n";
  print "[DEBUG] service: $service\n" if $service;
  print "[DEBUG] fabrics: $fabrics\n" if $fabrics;
  print "[DEBUG] file: $file\n" if $file;

}

# make sure relrepo is updated
update_repo( $itops_home );

# make sure relrepo is updated
update_repo( $relrepo );

# get list of apps, and check one by one
my $apps_ref = get_apps();

for my $app ( @{$apps_ref} ) {

  check_it( $app );

}

my $ref = array_unique( \@failed_apps );

if ( @$ref ) {
  print STDERR "\n";
  print STDERR '*' x 80, "\n";
  print STDERR "The following apps failed:\n";
  print STDERR '*' x 80, "\n";
  print join("\n", @$ref), "\n";
}

exit;


#===============================
# subs
#===============================
sub update_repo {

  my $repo = shift;

  print STDERR "Updating repo: $repo...\n" if $debug or $verbose;

  run_cmd("svn update $repo");

}


sub run_cmd {

  my $cmd = shift;

  system( $cmd );

  if ( $? == -1 ) {
    print "ERROR: failed to run $cmd. \n";
    return 1;
  } 
  elsif ( $? & 127 ) {
    printf "child proc died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? "with" : "without";
    return 1;
  }
  else {
    my $exit_value = $? >> 8;
    printf "child proc exited with value %d\n", $exit_value;
    print "Successfully ran $cmd\n" if $exit_value == 0;
    return 0;
  }

}

sub get_apps {

  my @apps;

  if ( $service ) {
    push @apps, $service;
  }

  if ( $file ) {
    my $_ref = get_apps_from_file( $file );
    push @apps, @{$_ref};
  }  

  \@apps;

}

sub get_apps_from_file {

  my $file = shift;
  
  my @apps;
  open my $f, "<", $file or die "cannot open file $file for reading: $!\n";
  while(<$f>) {
    chomp;
    next if /^#/;
    s/\s+//g;
    push @apps, $_;
  }
  close $f;

  \@apps; 

}

sub get_warname {

  my $app = shift;

  my $envname = $fabrics =~ /PROD/ ? 'ela4' : 'beta';

  print "envname : $envname\n" if $debug;

  chomp(my $warname = `$getwar_scr -e $envname --getwar $app --nosvn`);

  $warname;

}


sub get_appversion {

  my $app = shift;

  my $appversion;  # e.g., 0.0.1130-RC2.7409

  my $file_release_bom = "$relrepo/releases/$release/RELEASE.BOM"; 

  my $warname = get_warname( $app );

  unless ( $warname ) {
    print "[WARNING]: no warname found for app: $app\n";
    return;
  }

  # now that we have the warname, find the appversion in RELEASE.BOM
  open my $f, "<", $file_release_bom or die "cannot open $file_release_bom for reading: $!\n";
  while(<$f>) {
    next if /^#/;
    chomp;
    $appversion = $1 if /^$warname.*\|(.*)/; 
  }
  close $f;

  $appversion;

}



sub check_it {

  my $app = shift;
  print "\n";
  print '=' x 80, "\n";
  print "[INFO] checking app: $app\n";

  my $br_dir = $release;  # release is: R1130
  $br_dir =~ s/R//; # 1130
  my $relnum = $br_dir; # 1130
  $br_dir = 'BR_REL_' . $br_dir;   # now we should have e.g., BR_REL_1130
  
  # get appversion
  my $appversion = get_appversion( $app );

  unless ( $appversion ) {
    print "[WARNING]: no APPVERSION found for app: $app\n";
    push @failed_apps, $app;
    return;
  }

  print '*****before cd home: ', cwd(), "\n" if $debug;

  chdir($home_dir);

  print 'after cd home: ', cwd(), "\n" if $debug;

  # cfg2 init -b BR_REL_1130 -s auth-server
  my $cmd_init = "$cfg2 init -b $br_dir -s  $app  $relnum ";
  print "---- $cmd_init \n" if $verbose;
  my $ret = ` $cmd_init 2>&1 `;
  push @failed_apps, $app if $ret =~ m{WARNING|ERROR};
  print $ret, "\n";

  # chdir to $br_dir

  print 'before cd br_dir: ', cwd(), "\n" if $debug;

  chdir( $br_dir );
  
  print 'after cd br_dir: ', cwd(), "\n" if $debug;

  # only do check if check is opted
  if ( $check ) {

    # cfg2 check -s auth-server -a 0.0.1128-RC2.7304
    my $cmd_check = "$cfg2 check -s $app -a $appversion";
    print "---- $cmd_check \n" if $verbose;
    my $ret = ` $cmd_check 2>&1 `;
    push @failed_apps, $app if $ret =~ m{WARNING|ERROR};
    print $ret, "\n";

  }

  #  cfg2 publish -f PROD-ELA4,PROD-ECH3 -s auth-server -a 0.0.1128-RC2.7304
  my $cmd_publish = "$cfg2 publish -f $fabrics -s $app -a $appversion ";
  if ( $publish ) {
    $cmd_publish .= " -p ";
  }
  print "---- $cmd_publish \n" if $verbose;
  $ret = ` $cmd_publish 2>&1  `;
  push @failed_apps, $app if $ret =~ m{WARNING|ERROR};
  print $ret, "\n";

  print 'end of check_it: ', cwd(), "\n" if $debug;

}

