#!/bin/env perl 
#
# lwang: betastg
#
unless ( `hostname` eq 'esv4-be05.stg' ) {
  print "\nYou have to  run it on esv4-be05.stg after checking out itops.  \n\n"; exit;
}

use warnings;
use strict;

use Getopt::Long;

my $help;
my $debug;
my $execute;
my $reporoot;

GetOptions(
	"reporoot=s" => \$reporoot,
	"help" => \$help,
	"debug" => \$debug,
	"execute" => \$execute,
);

my $usage =<<USAGE;

Usage:

  $0	[ -reporoot <repo_root_dir> ] 	
	---debug --help --execute

Examples:

	\$  $0 [ -reporoot <repo_root_dir> ] [ -h ] [ -d ] [ -execute] 

USAGE


#
if ( $help ) {
  print $usage; exit;
}


# globals

my $repo_root_dir = $reporoot ? $reporoot : "/export/home/lwang/betastg/lw";


# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});




#umask 0022;
#mkdir "$drop_dir_root/$work_dir" if $execute;

# now get to work...


print "repo_root_dir: $repo_root_dir\n" if $debug;


my %manif = get_manif();

my @apps = keys %manif;

print "all apps: @apps\n" if $debug;

for my $app ( @apps ) {
  print "\nDealing with $app: ";
  my @machines = split(" ", $manif{$app});

  # make sure we are working on existing dirs
  next if ! -d  "$repo_root_dir/$app" ;

  for my $m ( @machines ) {
    print "\ton $m\n";
   
    # mkdir 
    my $cmd =  qq[mkdir -p $repo_root_dir/$app/$m  ];

    print "Running: $cmd\n";
    system( $cmd ) if $execute;


    # mv 
    if ( -f "$repo_root_dir/$app/$m/server_conf.sh" &&  -f "$repo_root_dir/$app/server_conf.sh" ) {
      warn "WARNING: found server_conf.sh in both $repo_root_dir/$app and $repo_root_dir/$app/$m. Please inspect!\n";
      next;
    } 
    else {

      if ( ! -f "$repo_root_dir/$app/server_conf.sh" ) {
        warn "WARNING: could not find $repo_root_dir/$app/server_conf.sh. Please inspect.\n";
      } 
      else {
        $cmd = qq[cp $repo_root_dir/$app/server_conf.sh $repo_root_dir/$app/$m ];

        print "Running: $cmd\n";
        system( $cmd ) if $execute;
      }
    }
  }
}


exit(0);


sub get_manif {
  my $manif_file = "$itops_home/manif/manifest_stg";

  my %manif;
  open my $f, "<", $manif_file or die "cannot open file $manif_file: $!\n";
  while (<$f>) {
    chomp;
    push @apps, $1 if m{(.*?)\t.*};  
    if ( m{(.*?)\t(.*)} ) {
      $manif{$1} = $2; 
    }
  }
  close $f;

  return %manif;
}


