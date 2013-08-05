#!//bin/perl -w
# 
# lwang: The purpose of this script is to generate app port mapping for a given envname
#
use strict;
use Getopt::Long;
use lib "../lib/perl";
use MYCM qw( is_frontend_app get_frontend_installed_dir );

# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});

my $help;
my $envname;
my $appname;
my $debug;

GetOptions(
	"help" => \$help,
	"envname=s" => \$envname,
	"appname=s" => \$appname,
	"debug" => \$debug,

);

usage() if $help;

unless ( $envname ) {
  print "I need envname: -e <envname> \n";
  usage(); 
  exit;
}


# only for prod 
my $manif_file = "$ENV{ITOPS_HOME}/manif/manifest_$envname";
#print $manif_file;

my $container_mapping_file = "$ENV{ITOPS_HOME}/manif/container_mapping_$envname";

# if appname provided

if ( $appname ) {

  handle_peoplesearch();

  my $first_machine = get_first_machine($appname);

  my $port = get_port( $first_machine, $appname);
  
  print $appname, "\t";
  print $port ? $port : "", "\n";
  
  exit 0;

}

# otherwise, do for all apps

my @apps_all = `cat $manif_file | cut -f1`;

chomp(@apps_all);

for my $appname ( @apps_all ) {

  handle_peoplesearch();

  my $first_machine = get_first_machine($appname);

  my $port = get_port( $first_machine, $appname);
  
  print $appname, "\t";
  print $port ? $port : "",  "\n";
 

}




exit(0);


############### subs
sub usage {

  print <<EOM;

usage $0:  [ -h | --help ] [ -d | --debug ] { -e | --envname <envname> } [ -a | --appname <appname> ]  

EOM

  exit 0;

}


sub get_port {

  my ($first_machine, $app) = @_;

  my $port;

  if ( is_frontend_app( $app, $container_mapping_file ) ) {

#########################
#
# TODO: dynamically get port for FE, 
#
# 	the implementation here is to look at the first one if there are more than one 'Connector port' found in server.xml.... 
#	is this a reasonable assuption?   if not, changes have to be made here
#
#########################


    my $installed_dir = get_frontend_installed_dir( $app, $container_mapping_file ) ;

    my $cmd = qq[ ssh $first_machine \"  cd /export/content/$installed_dir/i001/conf; grep 'Connector port' server.xml  | sed -e 's/.*=//'  -e 's/[\\"]//g'  | head -1   \"  2>/dev/null  ]; 
    print "\nRunning command: \n\t$cmd\n" if $debug;
    
    $port = ` $cmd `;

  } 
  else {

    my $cmd = qq[ ssh $first_machine \" grep CONTAINER_SERVER_PORT /export/content/$app/i001/conf/* | sed 's/.*CONTAINER_SERVER_PORT=//' \" 2>/dev/null  ];
    print "\nRunning command: \n\t$cmd\n" if $debug;
    $port = ` $cmd `;

  }

  chomp($port) if $port;

  return $port if $port;
  return;

}

# for instance in i001 i002 i003 i004 i005 i006 i007 i008 i009 i010 i011 i012 ; do

sub get_port_for_peoplesearch {

  my ($first_machine, $app) = @_;

  my $ret;

  for my $i ( qw(i001 i002 i003 i004 i005 i006 i007 i008 i009 i010 i011 i012 i013) ) {
    my $cmd = qq[ ssh $first_machine \" grep CONTAINER_SERVER_PORT /export/content/$app/$i/conf/* | sed 's/.*CONTAINER_SERVER_PORT=//' \" 2>/dev/null  ];
    print "\nRunning command: \n\t$cmd\n" if $debug;
    my $port = ` $cmd `;
  
    chomp($port);

    $ret .= "$i: $port | " if $port;

  }
  return $ret if $ret;
  return;

}


sub get_first_machine {

  my $app = shift;

  my $machines;

=pod
  open my $f, '<', "$manif_file" or die "cannot open file $manif_file for opening: $!\n";
  while (<$f>) {
    chomp;
    $machines = $1 if /^$app\t(.*)/; 
  }
  close $f;

  die "ERROR: either I am not able to find app: $app or I found no machine for the app.\n" unless $machines;

  # get the first machine
  my @machines = split (" ", $machines);
=cut

  my @machines = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $envname --svc $app  2>/dev/null | grep -v 'At revision' `; 
  chomp(@machines);

  my $first_machine = shift( @machines );
#  print $first_machine, "\t";
  
  # 
  # first machine should not be cch box or ss01
  #
  if ( $first_machine =~ /cch01/ or $first_machine eq 'ss01.prod' ) {
    $first_machine = shift( @machines );
  }


  return $first_machine if $first_machine;
  return;

}


sub get_all_machines_for_peoplesearch {

  my $cmd = qq[ $itops_home/bin/cmtool.pl -a get_pool_hosts -env $envname -pool people-search ];

  my $hosts = `$cmd`;
  chomp($hosts);

  return $hosts;

}

sub handle_peoplesearch {

  # for people-search
  if ( $appname && $appname eq 'people-search' ) {

    my $phosts = get_all_machines_for_peoplesearch();
    
    for my $m ( split(" ", $phosts) ) {
      my $port = get_port_for_peoplesearch( $m, $appname);
      print "$appname\t$m : $port\n";
    }

  }

}



