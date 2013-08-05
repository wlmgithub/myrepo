#!/bin/perl -w
#
# lwang: for databus maintenance use
#
# cf:	~/maintenance
#
#
# sample run: 
# (deprecated: ./doit.pl -comp company-server  -operation pause   -source companyDirectory  -d )
#  ./doit.pl -comp anet-cloud -operation restart  -d
#
#
#
use strict;
use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use Utils qw( diff_of_A_and_B );


# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});

my $myversion = '0.0.9';

my $comp;   			# component name, e.g., company-name
my $opt_operation;
my $operation;
my $environment = 'stg';  	# buse 'stg' by default
my $opt_machine;
my $opt_file; 			# input file containing a list of components
my $noask;			# well, no bother asking :)

my $debug;
my $help;
my $execute;


GetOptions( 
        "comp=s" => \$comp,
        "operation=s" => \$opt_operation,
        "machine=s" => \$opt_machine,
        "environment=s" => \$environment,
        "file=s" => \$opt_file,

        "noask"  => \$noask,
        "execute"  => \$execute,
        "debug"  => \$debug,
        "help"  => \$help,
);


my $thisprog = $0;

my $usage = <<USAGE;

VERSION: 

  $myversion

USAGE:

  $0 { --comp <component>  }  { --operation <operation> } 	
     --machine <machine> --environment <environment> --execute  --noask --debug --help

NOTES:

  * please make sure the "mapping" file in the same directory is updated.
  * use --execute to actually do it, otherwise, only shows what would have run.
  * <environment> is default to 'stg'.
  * if --machine is not provided, all machines for the given app will be used.
  * --noask : no bother asking

EXAMPLES:

  ********* for showing [ safe to run ]
  * $0 --comp repdb-server --operation suspend
    : shows what would have run if 'suspend' operation is to be invoked for repdb-server on stg

  * $0 --comp repdb-server --operation suspend --machine esv4-rdb05.stg
    : shows what would have run if 'suspend' operation is to be invoked for repdb-server on stg, only for host esv4-rdb05.stg

  * $0 --comp repdb-server --operation suspend --env ech3
    : shows what would have run if 'suspend' operation is to be invoked for repdb-server on ech3

  * $0 --comp repdb-server --operation suspend --env ech3 --machine ech3-rdb13.prod
    : shows what would have run if 'suspend' operation is to be invoked for repdb-server on ech3, only for host ech3-rdb13.prod


  ********* for executing [ BE CAREFUL! ]
  * $0 --comp repdb-server --operation suspend --execute
    : invoke 'suspend' operation for repdb-server on stg

  * $0 --comp repdb-server --operation suspend --machine esv4-rdb05.stg --execute
    : invoke 'suspend' operation for repdb-server on stg, only for host esv4-rdb05.stg

  * $0 --comp repdb-server --operation suspend --env ech3 --execute
    : invoke 'suspend' operation for repdb-server on ech3

  * $0 --comp repdb-server --operation suspend --env ech3 --machine ech3-rdb13.prod  --execute
    : invoke 'suspend' operation for repdb-server on ech3,  only for host ech3-rdb13.prod



USAGE


if ( $help ) {
  print $usage; 
  exit;
}


unless  (  $comp &&  $opt_operation ) {
  myprint("ERROR:  --comp and --operation are required.");
  print $usage; exit;
}


alert_mapping_file_up_to_date() if $execute;

my $port = get_port( $comp );
my %operation_of;
my %objname_of;

check_comp();
parse_mapping();

#print Dumper(%operation_of) if $debug;
#print Dumper(%objname_of) if $debug;

# now that we have the mappings...
check_operation();




myprint ("INFO: component = $comp") if $debug;
myprint ("INFO: operation = $operation") if $debug;
myprint ("INFO: environment = $environment") if $debug;
myprint ("INFO: objname = $objname_of{$comp}") if $debug;

myprint ("INFO: port = $port") if $debug;


if ( $opt_machine ) {

  show_msg( $comp, $operation, $environment, $opt_machine);
  do_it_on( $opt_machine );

}
else {


  my $machines_str = get_machines( $comp );
  my @machines = split(/\s+/, $machines_str);
  
  #print join("\n", @machines);
  
  
  for my $m ( @machines ) {
  
    show_msg( $comp, $operation, $environment, $m);
    do_it_on( $m );
  
  }

}


exit 0;


########### SUBS:

sub show_msg {
  my ($c,  $o, $e, $m) = @_;

  print "\n";
  print '=' x 50, "\n";
  print "$c -> $m \n";
  print "    operation: $o \n";
  print "  environment: $e \n";
  print '=' x 50, "\n";
  print "\n";

}



sub alert_mapping_file_up_to_date {

  print <<EOM;

Please make sure that the mapping file is up to date.

EOM

  unless  ( $noask ) {

    print "Continue? (y/n):";
  
    chomp(my $ans = <STDIN> );
    unless  ( $ans =~ /^y/i ) {
      exit; 
    } 

  }

}



sub check_operation {

  if ( $operation_of{$comp} =~ /UpdatesFromDatabus/ ) {
    # allowed operations: suspend, restart
    unless  ( $opt_operation eq 'suspend' or $opt_operation eq 'restart' ) {
      myprint("ERROR: allowed actions for $comp: suspend, restart.");
      exit;
    }
    else {
      $operation = $opt_operation."UpdatesFromDatabus";
    }
  }
  else {
    # allowed operations: pause, resume
    unless  ( $opt_operation eq 'pause' or $opt_operation eq 'resume' ) {
      myprint("ERROR: allowed actions for $comp: pause, resume.");
      exit;
    }
    else {
      $operation = $opt_operation;
    }
  }

}



sub check_comp {
  
  unless ( `egrep "$comp\t" "mapping" ` ) {
    myprint("ERROR: cannot file \"$comp\" in mapping file.\n");
    exit;
  }

}

sub parse_mapping {

  my $mapping_file = "mapping";
  open my $f, "<", "$mapping_file" or die "cannot open file: $mapping_file for reading: $!\n";
  while(<$f>) {
    chomp;
    next if /^\s+/;
    next if /^#/;
    if (m{$comp\t(.*)\t(.*)}) {
      $operation_of{$comp} = $1;
      $objname_of{$comp} = $2;
    }
  }
  close $f;

}




sub myprint {

  my $msg = shift;

  print STDERR "$msg\n";

}


sub get_port {

  my $comp = shift;

  my $app_port_file = "$itops_home/manif/app_port";
  my $port;

  open my $f, "<", "$app_port_file" or die "cannot open file: $app_port_file: $!\n";
  while (<$f>) {
    chomp;
    if (/^$comp\t(.*)/) {
      $port = $1;  
    }
  }
  close $f;

  $port;

}


sub get_source {
  
  my $comp = shift;

  my $app_name_file = "$itops_home/manif/app_name";
  my $source;

  open my $f, "<", "$app_name_file" or die "cannot open file: $app_name_file: $!\n";
  while (<$f>) {
    chomp;
    if (/^$comp\t(.*)/) {
      $source = $1;  
    }
  }
  close $f;

  $source;

}


sub get_machines {

  my $comp = shift;

  my $manifest_file = "$itops_home/manif/manifest_${environment}";
  my $machines_str;

  open my $f, "<", "$manifest_file" or die "cannot open file: $manifest_file: $!\n";
  while (<$f>) {
    chomp;
    if (/^$comp\t(.*)/) {
      $machines_str = $1;
    }
  }
  close $f;

  $machines_str;

}

sub get_databus_type {

  my $url = shift;

  my @lines = `wget -o /dev/null -O - $url | grep com.foobar.databus:type= `;

  foreach ( @lines ) {
  }


}



sub do_it_on {

  my $m = shift;

  ########################################
  #
  # * for pause/suspend, grepping _BY_USER, reason: more universal 
  # * what happens if a wget hangs? TODO: need to handle this case....
  #
  ########################################

  my $cmd;
  
  if ( $opt_operation eq 'pause' or $opt_operation eq 'suspend' )  {

    $cmd = qq[ ssh $m ' /usr/sfw/bin/wget -q -O /dev/null "http://localhost:${port}/jmx/invoke?operation=${operation}&objectname=$objname_of{$comp}";   echo "Pausing databus .....";  if [ -e "/export/content/glu/apps/$comp" ]; then tail -100 /export/content/glu/apps/$comp/i001/logs/*_databus.log | grep "_BY_USER" ; else tail -100 /export/content/$comp/i001/logs/*_databus.log | grep "_BY_USER" ; fi  ' ];

  }
  elsif ( $opt_operation eq 'resume' or $opt_operation eq 'restart' ) {

    $cmd = qq[ ssh $m ' /usr/sfw/bin/wget -q -O /dev/null "http://localhost:${port}/jmx/invoke?operation=${operation}&objectname=$objname_of{$comp}";    echo "Resuming databus ....."; if [ -e "/export/content/glu/apps/$comp" ]; then tail -100 /export/content/glu/apps/$comp/i001/logs/*_databus.log | grep maxSCNSeen | grep resume; else tail -100 /export/content/$comp/i001/logs/*_databus.log | grep  maxSCNSeen | grep resume; fi ' ];

  }

  if ( $execute ) {

    unless ( $noask ) {

      # really do it
      myprint ("Do you really want to run?(y/n)");
      chomp(my $answer = <STDIN>);
      if ( $answer =~ /^y/i ) {
        myprint("Running cmd: $cmd ") if $debug;
        system( $cmd );
      }

    }
    else {

      myprint("Running cmd: $cmd ") if $debug;
      system( $cmd );

    }

  }
  else {
    # info
    myprint("INFO: would have run:\n$cmd\n");

  }

}



__END__


