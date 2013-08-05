#!/usr/bin/perl -w
#
# lwang: This is a wrapper around configprocessor.sh to check configs 
#
# 
#
use strict;
use Getopt::Long;
use Data::Dumper;

use lib "../lib/perl";
use MYCM qw( get_content_in_file prop_in_file  );
use Utils qw( in_A_not_in_B array_unique );

# set autoflush
$| = 1;

# ugly globals
my $rm = "/bin/rm";
my $wget = "/usr/sfw/bin/wget";
my $script_root = "/export/content/config-split";
my $build_dir_root;
#my $build_dir_root = "/export/content/releases";
#my $build_dir_root = "/export/content/build.qa.releases";
chomp( my $host_running_on = `hostname`);
if ( $host_running_on  eq 'rotozip.corp' ) {
  $build_dir_root = "/export/content/build.qa.releases";
}
elsif ( $host_running_on eq 'esv4-build01.corp' ) {
  $build_dir_root = "/export/content/releases";
}


my $artifactory_release_url = 'http://esv4-cm01.corp:8081/artifactory/release/';

my $configprocessor = "$script_root/configuration-processor-cmdline/bin/configprocessor.sh";
my $empty_springconfig = "$script_root/extservices.springconfig.empty";
chomp( my $me = `whoami` );
my $my_log_dir = "/export/home/$me/config_split_logs";
my $my_war_dir = "/export/home/$me/config_split_wars";

mkdir $my_war_dir unless -d $my_war_dir;

my $cfg_url_root; 
my $app_env;
my $ccs_host;
my $ccs_root;
my $ssh = '/bin/ssh';
my %summary_report; # key is appname, value is ref to array of really_missing_props
my %duplicate_keys; # key is appname, value is dup key name
my %extra_keys;     # key is appname, value is extra key name

my %build_dir_of;   # for GLU, build# of each app may be different
 
#
# ugly exclusions
#
my @known_excluded_props = qw(
  com.foobar.container.classpath
  com.foobar.app.version.strict
  people.search.partition.count
  people.search.partition.databus.source
  people.search.partition.start
  liar.member.index.directory
  activemq.consumer.brokerURL
  
);


# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});

my $app_ccs_dirname_file = "$itops_home/manif/app_ccs_dirname";

my ($appname, $warname, $build, $help, $debug);
my ($version, $envname, $machine, $instance, $ccsdir );
my $use_empty_springconfig;
my $report_only_missing;
my $file; # file containing list of components for checking
my $release; # for GLU
my $novalidation;
my $nomachinelevel;
my $email;
my $useartifactory = 1;   # use artifactory by default.  Change it to 0 to do otherwise
my $noartifactory;

GetOptions(
	"release=s"                  => \$release,
	"appname=s"                  => \$appname,
	"warname=s"                  => \$warname,
	"build=s"                    => \$build,
	"version=s"                  => \$version,
	"envname=s"                  => \$envname,
	"machine=s"                  => \$machine,
	"instance=s"                 => \$instance,
	"ccsdir=s"                   => \$ccsdir,
	"file=s"                     => \$file,
	"help"                       => \$help,
	"debug"                      => \$debug,
	"email"                      => \$email,
	"use_empty_springconfig"     => \$use_empty_springconfig,
	"report_only_missing"        => \$report_only_missing,
	"novalidation"               => \$novalidation,
	"useartifactory"               => \$useartifactory,
	"noartifactory"               => \$noartifactory,,
	"nomachinelevel"             => \$nomachinelevel,
);

my $usage =<<USAGE;

usage: $0 { -rel | --release <release> } { -a | --appname <appname> } { -w | --warname <warname> } [ -b | --build <build> ]
          [ -v | --version <version> ] [ --envname <envname> ] [ -m | --machine <machine> ] [ -c | --ccsdir <ccs_dir_name> ]
          [ -i | --instance <instance> ] [ -f | --file <file_containing_comps> ] [ -u | --use_empty_springconfig ]
          [ -rep | --report_only_missing ] [ -nov | --novalidation ] [ -nom | --nomachinelevel ] [ -h | --help ] [ -d | --debug ]  [ --email ]
          [ -usea | --useartifactory ]  [ -noa | --noartifactory ]

where:
	- release: release name, e.g., R940 ( used to find release build dir )
	- appname: application name or component name , e.g., oms-server
	- warname: warfile name: e.g., oms
	- build: build string, e.g., build-481_5_1991-prod
	- version: version string, e.g., 0.0.482
	- envname: environment name, e.g., stg/ech3
	- machine: machine name without env suffix, e.g., esv4-be05
	- instance: instance name, e.g., i001
	- ccsdir: ccs dir name name, e.g., nhome
	- file: filename containing a list of components for checking
	- use_empty_springconfig: used if empty springconfig file is used
	- report_only_missing: used if only missing properties to be reported 
	- novalidation: no validation performed
	- nomachinelevel: no machine and/or instance level validation performed

notes:
	- release name is required
	- either -a or -f is required
	- options -f and -m are mutually exclusive
	- if no <build> given, it defaults to the build in CURRENT_BUILD.txt
	- if no <envname> given, it defauts to 'stg'
	- appname and component name are used synonymously

examples:
	1)
	$0 -rel R940 -a oms-server
		: This will check configs of app oms-server in R940, using default env: stg

	2)
	$0 -rel R940 -a oms-server -env ech3
		: This will check configs of app oms-server in R940, using env: ech3


	3)
	$0 -rel R940 -f ~/code/itops/releases/940
		: This will check configs of apps in file ~/code/itops/releases/940 for R940, using default env: stg

	4)
	$0 -rel R940 -f ~/code/itops/releases/940 -env ech3
		: This will check configs of apps in file ~/code/itops/releases/940 for R940, using using : ech3

	5)
	$0 -rel R940 -a nhome -ccsdir nhome
		: This will check configs of nhome with nhome as the dirname in ccs
		: (this is used when the script does not provide a valid ccs dirname)


USAGE


if ( $help ) {

  print $usage; exit;

}

unless ( $release ) {

  print $usage; exit;

}

if ( $noartifactory ) {

  $useartifactory = 0;

}

$release = uc $release; # in case ....

# now that we have release Rxxx, we should read MASTER bom to construct build_dir_of hash
#
# currently using the following files to find related info:
# 	* LEGACY-MASTER.BOM for apps
#	* BIULD.BOM for warname
#	* config.properties for ccs_dirname
#
#
my $legacy_bom_file = "$build_dir_root/$release/LEGACY-MASTER.BOM";
my $build_bom_file = "$build_dir_root/$release/BUILD.BOM";  # for getting warname mapping
my $release_bom_file = "$build_dir_root/$release/RELEASE.BOM";  # for getting rest of path to artifactory_release_url

my $build_string;
open my $f, "<", $legacy_bom_file or die "Cannot read  file: $legacy_bom_file: $!\n";
while ( <$f> ) {
  chomp;
  next if /^#/;
  if ( /(.*)=(.*)/ ) {
    $build_dir_of{$1} = $2; 
    $build_string = $2;
  }
}

close $f;

print Dumper(%build_dir_of) if $debug;



if ( $file && $appname ) {

  print "file and appname are mutually exclusive.\n";
  print $usage; exit;

}

if ( $file && $machine ) {

  print "file and machine are mutually exclusive.\n";
  print $usage; exit;

}

unless ( $file || $appname ) {

  print "I need either file or appname.\n";
  print $usage; exit;

}


#unless ( $build ) {
#
#  $build = get_default_build();
#
#}
    
# by default, use stg
unless ( $envname ) {

  $envname = 'stg';
  $cfg_url_root = "http://esv4-be05.stg:10093/configuration/get";
  $app_env = "STG-ALPHA";
  $ccs_host = "esv4-be05.stg";
  $ccs_root = "/export/content/repository";

}

my $ccs_dirname_mapping_file = "$itops_home/mappings/app_container_${envname}";  #  use this one in itops dir until Ivo provides the mapping in the release dir

unless ( $version ) {

  $version = get_default_version();

}

$envname = lc $envname; # in case...

if ( $envname eq 'stg' ) {

  $cfg_url_root = "http://esv4-be05.stg:10093/configuration/get";
  $app_env = "STG-ALPHA";
  $ccs_host = "esv4-be05.stg";
  $ccs_root = "/export/content/repository";

} elsif ( $envname eq 'beta' ) {

  $cfg_url_root = "http://esv4-be05.stg:10093/configuration/get";
  $app_env = "STG-BETA";
  $ccs_host = "esv4-be05.stg";
  $ccs_root = "/export/content/repository";

} elsif ( $envname eq 'ech3' ) {

  $cfg_url_root = "http://ech3-cfg-vip-a.prod:10093/configuration/get";
  $app_env = "PROD-ECH3";
  $ccs_host = "ech3-cfg02.prod";
  $ccs_root = "/export/content/master_repository";

} elsif ( $envname eq 'ela4' ) {

  $cfg_url_root = "http://ela4-cfg-vip-z.prod.foobar.com:10093/configuration/get";
  $app_env = "PROD-ELA4";
  $ccs_host = "ela4-glu02.prod";
  $ccs_root = "/export/content/master_repository";


} elsif ( $envname eq 'prod' ) {

  $cfg_url_root = "http://cfg-vip-a.prod:10093/configuration/get";
  $app_env = "PROD-ESV4";

} elsif ( $envname eq 'ei1' ) {

  $cfg_url_root = "http://esv4-be29.corp:10093/configuration/get";
  $app_env = "EI1";
  $ccs_host = "esv4-be29.corp";
  $ccs_root = "/export/content/repository";

} elsif ( $envname eq 'ei3' ) {

  $cfg_url_root = "http://esv4-be44.corp:10093/configuration/get";
  $app_env = "EI3";
  $ccs_host = "esv4-be44.corp";
  $ccs_root = "/export/content/repository";


}

# make sure relrepo is updated
update_relrepo();

# read apps from file, if any
if ( $file ) {

  my @apps =  get_apps_in_file($file);

  # validate apps before checking configs
  #validate_app( \@apps ) unless $novalidation;

  for my $app ( @apps ) {
    print "\n\n================ INFO: Checking app: $app\n\n";
      check_app($app);
  }

} else {
  #validate_app( [$appname] ) unless $novalidation;
  check_app( $appname );

}


unless ($report_only_missing) {

  make_report_on_extra_keys();

  make_report_on_duplicate_keys();

}

make_report();


  
exit 0;

#===============================
# subs
#===============================
sub update_relrepo {

  die "Please have your RELREPO environment variable set and point it to a checked-out workspace of relrepo.\n" unless $ENV{RELREPO};
  chomp(my $relrepo =  $ENV{RELREPO});

  print STDERR "Updating relrepo...\n" if $debug;

  run_cmd("svn update $relrepo");

}


sub validate_app {

  #
  # input: ref to apps array
  # output: none
  #
  # algorithm: 
  # 2 pass validatation: 
  #	1. validate appname in manifest file
  #	2. validate appname in app_name file
  #	3. if all validated, pass; otherwise, report and quit
  #
  # addition: 
  #	* also validate warname in app_name file
  #	* also validate existence of  war file  in build
  #
  my $appname_ref = shift;
  my @apps = @{$appname_ref};

  # if we are here, we should have been provided an appname, so no need to check
#  for my $appname ( @apps ) {
#    unless ( $appname ) {
#      print "\nappname is required.\n";
#      print $usage; exit;
#    }
#  }


  print STDERR "\nValidating ...\n";
  ###################
  #
  # validation 1
  #
  ###################

  my @invalids; # array of appnames not found in manifest 

  my $manif_file = "$itops_home/manif/manifest_$envname";
  for my $appname ( @apps ) {
    unless ( `egrep "^$appname\t" $manif_file` ) {
      push @invalids, $appname;
    }
  }

  if ( @invalids ) {
    print STDERR "\n\nThe following apps are not in $itops_home/manif/manifest_$envname:\n";
    print STDERR join("\n", @invalids), "\n";
    die "\nPlease double check and try again.\n";
  }
  # else pass

  ###################
  #
  # validation 2
  #
  ###################
  #
  # if all apps are valid, i.e., found-able in manifest file, then
  # check to see if it's found-able in app_name
  #  
  my @invalids_for_app_name; #  array for apps not found in app_name file
  for my $appname ( @apps ) {
    unless ( `egrep "^$appname=" $legacy_bom_file` ) {
      push @invalids_for_app_name, $appname;
    }
  }

  if ( @invalids_for_app_name ) {
    print STDERR "\n\nThe following apps are not in $legacy_bom_file:\n";
    print STDERR join("\n", @invalids_for_app_name), "\n";
    die "\nPlease double check and try again.\n";
  }
  # else pass

  ###################
  #
  # validation 3
  #
  ###################
  #  validate warname: is warname in app_name file? 
  my @no_warnames;
  for my $appname ( @apps ) {
    my $warname = $warname ? $warname : get_warname( $appname );
    push @no_warnames, $appname unless $warname;
  }

  if ( @no_warnames ) {
    print STDERR "\n\nThe following apps have no corresponding warname in $build_bom_file:\n";
    print STDERR join("\n", @no_warnames), "\n";
    die "\nPlease double check and try again.\n";
  }

  ###################
  #
  # validation  4
  #
  ###################
  # validate war file path in build dir
  my @no_war_files;
  for my  $appname ( @apps ) {
    my $warname = $warname ? $warname : get_warname( $appname );
    my $war_file = get_war_file($appname, $warname);
    push @no_war_files, $appname unless $war_file;
  }

  if ( @no_war_files ) {
    print STDERR "\n\nThe following apps do not seem to be built for release $release: \n";
    print STDERR join("\n", @no_war_files), "\n";
    die "\nPlease double check and try again.\n";
  }



}

sub get_apps_in_file {

  my $file = shift;
  my @apps;

  open my $f, "<", $file or die "cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^\s*$/;
    s/\s+//g;
    push @apps, $_;
  }
  close $f;

  if ( @apps ) {
    return @apps;
  } else {
    return;
  }

}

############
sub validate_appname_in_glu  {

  my $appname = shift;

  # ./gen_manif_from_glu.rb --env beta --getsvcs | grep -v 'At revision'
  chomp( my @all_apps = `$itops_home/glu/bin/./gen_manif_from_glu.rb --env $envname --getsvcs | grep -v 'At revision' ` ) ;

  my %hash;
  @hash{@all_apps}=();

  unless ( exists $hash{$appname} ) {
    print "I cannot find $appname in GLU... here is a list of valid apps:\n";
    print "@all_apps", "\n";
    exit; 
  } 

}


############
sub check_app {

  my $appname = shift;

  validate_appname_in_glu( $appname );

  my $warname = $warname ? $warname : get_warname( $appname );

  die "Cannot find warname for $appname: $!\n" unless $warname;

  if ( $debug ) {
#    print "build: $build\n";
    print "appname: $appname\n" if $appname;
    print "warname: $warname\n";
    print "version: $version\n";
    print "envname: $envname\n";
    print "machine: $machine\n" if $machine;
    print "cfg_url_root: $cfg_url_root\n";
    print "app_env: $app_env\n";
    print "ccs_host: $ccs_host\n";
    print "ccs_root: $ccs_root\n";
    print "build_dir_root: $build_dir_root\n";
  }

  # 
  # need to have a var to store CCS dir name
  # 
  # by default, we use warname
  # but for special cases, we'll have to deal with individually
  #
  # Special cases for app to dirname mapping come here:
  #
=pod
  my %app_to_ccs_dirname_mapping = (
    'people-search' => 'peopleSearchService',
    'people-search-broker' => 'peopleSearchBroker',
    'people-fbr' => 'people-fbr',
    'wotc-server' => 'wotc',
  );
=cut


  my $ccs_dirname ;
  $ccs_dirname = $ccsdir ? $ccsdir :  get_ccs_dirname($appname);

  unless ( $ccs_dirname ) {
    $ccs_dirname = $warname;
    $ccs_dirname =~ s/-war//;
  }

  unless ( $ccs_dirname ) {
    $ccs_dirname = $appname;
  }

  my $config_env_level = "$cfg_url_root/$app_env/extservices.springconfig"; 
  my $config_app_level = "$cfg_url_root/$app_env/$ccs_dirname/extservices.springconfig"; 

  my $config_ver_level;
  my $config_mch_level = "";
  my $config_inst_level = "";

  if ( $version  ) {
    $config_ver_level = "$cfg_url_root/$app_env/$ccs_dirname/$version/extservices.springconfig";

    if ( $machine ) {  # if -machine provided, use it
      $config_mch_level = "$cfg_url_root/$app_env/$ccs_dirname/$version/$machine/extservices.springconfig";
        if ( $instance ) {
          $config_inst_level = "$cfg_url_root/$app_env/$ccs_dirname/$version/$machine/$instance/extservices.springconfig";
        }
    }
    else {  # otherwise, find all hosts for the app, and form the string
      my $hosts = get_machines( $appname ); 
      my @hosts = split(" ", $hosts);
      for my $h ( @hosts ) {
        $config_mch_level .= ",$cfg_url_root/$app_env/$ccs_dirname/$version/$h/extservices.springconfig";
      }
    }
  }

  # special case for 'agent'....
  $config_mch_level = "" if $appname eq 'agent';
  
  my $my_outdir = "$my_log_dir/${ccs_dirname}.${envname}";

  # remove cache to avoid possible clashes
  if ( -e "$my_outdir" ) {
    system("$rm -rf $my_outdir" );
  }
  
  # digging into it....
  
  my $war_file;
  if ( $useartifactory ) {

    $war_file = get_war_file($appname, $warname);

  }
  else {

    $war_file = get_war_file_00($appname, $warname);

  }

  die "!!!!! ERROR: I cannot find war file !!!!!\n" unless $war_file;

#    print <<EOM;
#
#   !!!!! ERROR: I cannot find war file !!!!!
#
#   PLEASE NOTE: If the war file could not be found, it probably means the build is no longer there.
#         In this case, please grab the war file and put it somewhere and run the following command:
#
#    $configprocessor  -extract -outdir $my_outdir -application file:<path_to_your_war_file>  -config file:$empty_springconfig,$config_app_level,$config_ver_level
#  
#EOM
  
  my $cmd;
  
  if ( $use_empty_springconfig ) {
  
    $cmd = "$configprocessor  -extract -outdir $my_outdir -application file:$war_file  -config file:$empty_springconfig";
  
  } else {
  
    $cmd = "$configprocessor  -extract -outdir $my_outdir -application file:$war_file  -config file:$empty_springconfig,$config_app_level,$config_ver_level,$config_mch_level,$config_inst_level";
  
  }
  
  print "\n\nInspecting...\n";
  print "appname: $appname\n";
  print "warname: $warname\n";
  print "ccs_dirname: $ccs_dirname\n";

  print "\n\nRunning command:\n$cmd\n";
  
  #system( $cmd ) == 0 or die "cannot run cmd: $cmd : $!\n";
  run_cmd( $cmd );
  
  # now that we are done, we can remove the war_file
  unlink "$war_file" if -f "$war_file";

  # get env level config
  my $cmd_wget = "$wget $config_env_level  -O $my_outdir/env_level_extservices  -o /dev/null";
  
  #print "\nRunning command:\n$cmd_wget\n";
  
  #system( $cmd_wget ) == 0 or die "cannot run cmd: $cmd_wget: $!\n";
  run_cmd( $cmd_wget );
 
  my @props_really_missing;
  
  # if  missing_properties.log is not null, check each entry to see if it's in env_level_extservices
  #    if yes, report it, 
  #    otherwise, pass
  if ( -f  "$my_outdir/missing_properties.log" ) {
    chomp(my @missing_props = `cat $my_outdir/missing_properties.log`);
    for my $p ( @missing_props ) {
#      my $cmd_grep = qq(grep "\"$p\"" $my_outdir/env_level_extservices >/dev/null);
#      my $cmd_grep = qq(grep 'key="$p"' $my_outdir/env_level_extservices >/dev/null);
#      if ( system(  $cmd_grep ) != 0  ) {
      if ( ! prop_in_file("$p", "$my_outdir/env_level_extservices" )  ) {
        print "\n!!!!! Cannot find $p in $my_outdir/env_level_extservices. Please check!!!!";
        push @props_really_missing, $p;
      }
    }
  }
 
  #
  # if the value is a placeholder, 
  #	check to see if the placeholder is defined in the current ver_level or env_level, 
  #	and report the key to be really missing (or not) depending on the check 
  #

  # get ver level config file
  run_cmd( "$wget $config_ver_level  -O $my_outdir/ver_level_extservices_file  -o /dev/null");

  # 
  # if placeholder exists in resolved_extservices.springconfig, 
  # 	get them, and check whether they exists in env_level or ver_level
  #
  if ( -f "$my_outdir/resolved_extservices.springconfig" ) {

    my @placeholders;
    open my $f, "<", "$my_outdir/resolved_extservices.springconfig" ;
    while ( <$f> ) {
      chomp;
      push  @placeholders, $1 if m{ value=\"\$\{(.*?)\}};  # value="${...}..."
      if ( m{ value=\"\$\{(.*?)\}:\$\{(.*)\}\"} ) { # value="${lmt.host}:${lmt.prpc.port}"
        push @placeholders, $1;
        push @placeholders, $2;

      }
    }
    close $f;

    # if no placeholders, no need to do anything
    # if there is, check 

    if ( @placeholders ) {
      for my $p ( @placeholders ) {
#        my $cmd_grep = qq(grep "\\\"$p\\\"" $my_outdir/env_level_extservices $my_outdir/ver_level_extservices_file >/dev/null); 
#        my $cmd_grep = qq(grep 'key="$p"' $my_outdir/env_level_extservices $my_outdir/ver_level_extservices_file >/dev/null); 
#        my $ret =  system($cmd_grep);
#        if ( $ret != 0  ) {
        if ( ! prop_in_file("$p", "$my_outdir/env_level_extservices") && ! prop_in_file("$p", "$my_outdir/ver_level_extservices_file" )  ) {
          print "\n!!!!! Cannot find placeholder $p in $my_outdir/env_level_extservices or  $my_outdir/ver_level_extservices_file. Please check!!!!";
          push @props_really_missing, $p;
        }
      }
    }

  }

 
  #
  # exclude the @known_excluded_props from @props_really_missing
  #
  my $temp = in_A_not_in_B( \@props_really_missing, \@known_excluded_props );
  my $tmp = array_unique($temp);
  @props_really_missing = @$tmp;

  #
  # display and
  # also create really_missing_props file
  #
  if (  @props_really_missing ) {
    # it's possible that the props_really_missing may be in machine level

    unless ( $nomachinelevel ) {
      my @temp;
      for my $p ( @props_really_missing ) {
        my $cmd = qq[ $ssh $ccs_host ' cd $ccs_root/$app_env/$ccs_dirname/$version;  grep $p */extservices.springconfig */*/extservices.springconfig' 2>/dev/null ];
        unless ( `$cmd` ) {
          push @temp, $p;
        }
      }
      @props_really_missing = @temp;
    }

    if ( @props_really_missing ) {
      print "\n\n";
      print join("\n", @props_really_missing), "\n";
  
      my $really_missing_props_file = "$my_outdir/really_missing_props_file";
      open my $f, ">", $really_missing_props_file or die "cannot open file $really_missing_props_file for writing: $!\n";
        print $f join("\n", @props_really_missing), "\n";
      close $f;
  
      $summary_report{$appname} = \@props_really_missing;
    }

  }

  # when done, chmod the java tool's logs dir
  my $cmd_chmod = "/bin/chmod 777 $script_root/configuration-processor-cmdline/logs/* 2>/dev/null";
  
  #print "\nRunning command:\n$cmd_chmod\n";
  
  #system( $cmd_chmod ) == 0 or die "cannot run cmd: $cmd_chmod: $!\n";
  system( $cmd_chmod );
  

  #
  # detecting duplicate keys
  #
  my $ver_level_extservices_file = "$my_outdir/ver_level_extservices_file";

  check_duplicate_keys( $ver_level_extservices_file ); 

  print Dumper(%duplicate_keys) if $debug;


  #
  # detecting extra keys
  #
  my $env_level_extservices_file = "$my_outdir/env_level_extservices";
  my $resolved_extservices_file = "$my_outdir/resolved_extservices.springconfig" ;

  find_extra_props_if_any( $appname,  $env_level_extservices_file, $ver_level_extservices_file, $resolved_extservices_file );

  print Dumper(%extra_keys) if $debug;


  # 
  unless  ( $file ) {
    print "\n\n===================================================\n";
    print "Done. Your result is at: $my_outdir ";
    print "\n===================================================\n\n";
  }
  
=pod

  if ( $find_extra) {

    # 
    # detecting extra props
    #
    my $env_level_extservices_file = "$my_outdir/env_level_extservices";
    my $resolved_extservices_file = "$my_outdir/resolved_extservices.springconfig" ;
  
    # $ver_level_extservices_file was already defined above before check_duplicate_keys
  
    my @extras = find_extra_props_if_any(  $env_level_extservices_file, $ver_level_extservices_file, $resolved_extservices_file );
  
    if ( $debug ) {
      print "extras: \n";
      print Dumper(@extras);
    }
    
    make_report_on_extra_keys( \@extras );

  }

=cut


} # end check_app

sub get_default_build {

  chomp( my $build = `head -1 $itops_home/deploy_script/CURRENT_BUILD.TXT` );
  return $build;

}

sub get_default_version {

#  chomp( my $raw_version=`echo $build | sed -e 's/build-//' -e 's/_.*//'` );
  chomp( my $raw_version=`echo $build_string | sed -e 's/_.*//' -e 's/build-//'` );
  return "0.0.$raw_version" ;

}

sub get_warname {

  my $appname = shift;
  my $warname;

  my @wars = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $envname --getwar $appname | grep -v 'At revision' `;

  if ( @wars > 1 ) {
    @wars = grep { !/static-common/ } @wars;
  }

  chomp(  $warname = pop @wars );

  return $warname ;

}


sub get_warname_00 {

  my $appname = shift;
  my $warname;

  open my $f, "<", $build_bom_file or die "Cannot open $build_bom_file for reading: $!\n";

  while (<$f>) {
    chomp;
    next if /^#/;
    $warname = $1 if /(.*)=\b$appname$/;    
  }
  close $f;

  return $warname ? $warname : undef;

}

sub get_war_file {

  my $appname = shift;
  my $warname = shift;

  my $url_to_warfile = "$artifactory_release_url";

  my $part1;
  my $part2;
  my $part3;
  my $war_suffix;


  # tap-war=com.foobar.network.tap|tap-war|0.0.522-RC2.3702
  # --or--
  # comm-anet-digest-war=ivy\:/com.foobar.network.comm/comm-anet-digest-war/0.0.524-RC1.3804
  open my $f, "<", $release_bom_file or die "cannot open RELEASE.BOM file: $!\n";
  while (<$f>) {
    chomp;
    if ( /^$warname=(.*?)\|(.*?)\|(.*)/ ||  /^$warname=ivy\\:\/(.*?)\/(.*?)\/(.*)/  ||  /^$warname=ivy:\/(.*?)\/(.*?)\/(.*)/ ) {
      $part1 = $1;
      $part2 = $2;
      $part3 = $3;

      $part1 =~ s/\./\//g;  # com.foobar.network.tap  -> com/foobar/network/tap
      $war_suffix = "$part2-$part3.war";

    } 
  }
  close $f;

  #  http://esv4-cm01.corp:8081/artifactory/release/com/foobar/network/tap/tap-war/0.0.522-RC2.3702/tap-war-0.0.522-RC2.3702.war
  $url_to_warfile .= "$part1/$part2/$part3/$war_suffix";

  print "$url_to_warfile\n" if $debug;

  my $cmd_wget = "$wget $url_to_warfile -O $my_war_dir/$war_suffix  -o /dev/null";
  print "99999 warname: =====$warname=====" if $debug;

  run_cmd( $cmd_wget );


  return "$my_war_dir/$war_suffix";

}


sub get_war_file_00 {

  my $appname = shift;
  my $warname = shift;

  my $war_file;
  
  my $build_dir = "$build_dir_root/$release/$build_dir_of{$appname}";

  print "$build_dir\n" if $debug;
  print "$appname\n" if $debug;
  print "$warname\n" if $debug;


  if ( -e "$build_dir/$warname/${warname}.war" ) {

    $war_file = "$build_dir/$warname/${warname}.war";

  } elsif ( -e "$build_dir/$appname/war/${warname}.war" ) {
  
    $war_file = "$build_dir/$appname/war/${warname}.war";

  } elsif ( -e "$build_dir/${warname}/war/${warname}.war" ) {
  
    $war_file = "$build_dir/${warname}/war/${warname}.war" ;
  
  } elsif ( -e "$build_dir/${appname}-war/${warname}.war" ) {
  
    $war_file = "$build_dir/${appname}-war/${warname}.war" ;
 
  } elsif ( -e "$build_dir/${appname}/${warname}.war" ) {
  
    $war_file = "$build_dir/${appname}/${warname}.war";
  
  } elsif ( -e "$build_dir/deploy/${appname}/webapps/${warname}.war"  ) {
  
    $war_file = "$build_dir/deploy/${appname}/webapps/${warname}.war";
  
  } elsif ( -e "$build_dir/${warname}" ) {
  
    $war_file = "$build_dir/${warname}" ;

  } elsif ( -e "$build_dir/${appname}" ) {
  
    $war_file = "$build_dir/${appname}" ;
  
  } 
 
  print "$war_file\n"  if $debug;

  return $war_file ? $war_file : undef;

}

sub get_machines {

  my $appname = shift;
  # rotozip.corp:lwang[617] ~/code/itops/glu/bin $ ./gen_manif_from_glu.rb --env ech3 --svc auth-server  --nosvn
  chomp(my $hosts = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $envname  --svc  $appname  --nosvn`);
  if ( $envname eq 'stg' ) {
    $hosts =~ s/\.$envname//g; # get rid of .stg
  } elsif ( $envname eq 'beta' ) {
    $hosts =~ s/\.stg//g; # get rid of .stg  # ideally stg-beta should have its own suffix, like .beta, but currently it shares the same .stg with stg-alpha, oh well....
  } elsif ( $envname eq 'ei1'  or $envname eq 'ei3' ) {
    $hosts =~ s/\.qa//g; 
    $hosts =~ s/\.corp//g; 
  } else {
    $hosts =~ s/\.prod//g; # get rid of .prod
  }
  return $hosts if $hosts;
  return;

}


sub get_machines_00 {

  my $appname = shift;
  # ./cmtool.pl -a get_pool_hosts -env stg -pool leo 
  chomp(my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $envname -pool $appname`);
  if ( $envname eq 'stg' ) {
    $hosts =~ s/\.$envname//g; # get rid of .stg
  } elsif ( $envname eq 'beta' ) {
    $hosts =~ s/\.stg//g; # get rid of .stg  # ideally stg-beta should have its own suffix, like .beta, but currently it shares the same .stg with stg-alpha, oh well....
  } elsif ( $envname eq 'ei1' or $envname eq 'ei3'  ) {
    $hosts =~ s/\.qa//g; 
  } else {
    $hosts =~ s/\.prod//g; # get rid of .prod
  }
  return $hosts if $hosts;
  return;

}

sub make_report {

  my $report_env;
  $report_env = "PROD-ECH3" if $envname eq 'ech3';
  $report_env = "PROD-ELA4" if $envname eq 'ela4';
  $report_env = "STG-BETA" if $envname eq 'beta';
  $report_env = "STG-ALPHA" if $envname eq 'stg';
  $report_env = "EI1" if $envname eq 'ei1';
  $report_env = "EI3" if $envname eq 'ei3';

  if ( keys %summary_report ) {
    #print Dumper %summary_report;
    print <<EOM;
    
##############################################################
#                   
#  Summary Report
#
#  Format:
#
# <component with misssing props>:
#	<list of properties missing for the component>
#                   
##############################################################

EOM
    
    # do a summary report
    while (my ($k, $v) = each %summary_report ) {
      print STDERR "$k:\n\t";
      print STDERR join("\n\t", @$v), "\n\n";
    }
  
  }
  else {

    print <<EOM;
    
##############################################################
#                   
#  Success! I did not find any missing properties!
#
##############################################################

EOM
 
  }

  # if --email is given...
  if ( $email ) {
    # create htdocs file
    my $outfile = "/export/content/http/i001/htdocs/cm/check_configs/${release}_${envname}";

    open my $f, ">", $outfile or die "cannot open  file $outfile for writing: $!\n";
  
    if ( keys %summary_report ) { 
      print $f <<EOM;
    
##############################################################
#                   
#  Summary Report for Release ${release} and ENV $report_env
#
#  Format:
#
# <component with misssing props>:
#	<list of properties missing for the component>
#                   
##############################################################

EOM
        while ( my ($k, $v) = each %summary_report ) {
       print $f "$k:\n\t";
        print $f join("\n\t", @$v), "\n\n";
      }
      close $f;

    } 
    else {
      print $f <<EOM;
    
##############################################################################################
#                   
#  Success! I did not find any missing properties for Release ${release} and ENV $report_env!
#
##############################################################################################

EOM
      
    }

    #
    system("chmod 777 $outfile 2>/dev/null");

    # send email
    my $cmd = qq[ echo "http://rotozip.corp.foobar.com/cm/check_configs/${release}_${envname} " | mailx -s "Config check result for ENV ${envname} and Release ${release} " siteops\@foobar.com  ]; 
    system( $cmd ) == 0 or die "cannot run cmd $cmd: $!\n";

  }

}

#sub find_extra_props_if_any(  $env_level_extservices_file, $ver_level_extservices_file, $resolved_extservices_file );

sub find_extra_props_if_any {

  my $appname = shift;
  my $env_file = shift;
  my $ver_file = shift;
  my $resolved_file = shift;


  my @env_keys = get_keys_in_file( $env_file );
  my @ver_keys = get_keys_in_file( $ver_file );
  my @resolved_keys = get_keys_in_file( $resolved_file );

  my @current_keys;
  push @current_keys, @ver_keys;
#  push @current_keys, @env_keys;
  
  # look for keys in current_keys but not in resolved keys 

  my $ref_current_keys  = array_unique( \@current_keys );
  my $ref_resolved_keys = array_unique( \@resolved_keys );

#  my $ref_extra_keys = in_A_not_in_B( \@current_keys, \@resolved_keys);
  my $ref_extra_keys = in_A_not_in_B( $ref_current_keys, $ref_resolved_keys);
  my @extra_keys = @$ref_extra_keys;

  if ( $debug ) {
    print "env_file = $env_file\n";
    print "ver_file = $ver_file\n";
    print "resolved_file = $resolved_file\n";
    print "\n";
    print "\n";
#    print "current_keys: ", @current_keys, "\n";
#    print "resolved_keys: ",  @resolved_keys, "\n";
  print "\n========== current_keys\n";
  print Dumper(@current_keys);
  print "\n========== resolved_keys \n";
  print Dumper(@resolved_keys);
    print "\n";
    print "\n";
  }

  # populate %extra_keys
  $extra_keys{$appname} = \@extra_keys if @extra_keys;

#  return @extra_keys if  @extra_keys ;
#  return;

}


sub get_keys_in_file {
  
  my $file = shift;
  my @keys;

  open my $f, "<", $file or die "cannot open file $file: $!\n";
  while (<$f>) {
    chomp;
    next if /^\s*$/;
    next if m{<!--} .. m{-->};
    next if m{<!--};
    my $key = $1 if m{entry key="(.*?)"};
    push @keys, $key if $key;
  }
  close $f;

  chomp(@keys);
  return @keys if @keys;
  return;
  
}


sub check_duplicate_keys {

  my $file = shift;
  
  if ( -e "$file" ) {

    my %count; # count all keys
    open my $f, "<", $file or die "cannot open file $file: $!\n";
    while (<$f>) {
      chomp;
      next if /^\s*$/;
      next if m{<!--} .. m{-->};
      next if m{<!--};
      my $key = $1 if m{entry key="(.*?)"};
      $count{$file}{$key}++ if $key;
    
    }
    close $f;

    # now stuff real %duplicate_keys 
    while (  my ($f,$k_ref)  = each %count  ) {
      while ( my ($k, $c) = each %{$k_ref} ) {
        $duplicate_keys{$f}{$k} = $c if $c > 1;
      }
    }

  }

}

sub make_report_on_duplicate_keys {
#
# %duplicate_keys = { 'file' => \{ 'key' => count } 
#                   }
#

  if ( keys %duplicate_keys  ) {

    print <<EOM;
    
##############################################################
#      
#  Duplicate Keys Report            
# 
#  Format:
#   
# <component with duplicate keys>:
#       <list of duplicate keys with dup degree>
#  
##############################################################

EOM

#    print "Duplicate keys found:\n";
    while ( my ($f,$k_ref)  = each %duplicate_keys ) {
      my $preso = $1 if $f =~ m{.*/(.*).$envname/.*};
      print "\n$preso:\n";
      while ( my ($k, $c) = each %{$k_ref} ) {
        print "\t$k $c\n" if $c > 1;
      }
    }
  } else {

    print <<EOM;
    
##############################################################
#                   
# Success! I did not find duplidate keys! 
#
##############################################################

EOM

   }

}

sub get_ccs_dirname {
#
# use config.properties for now    
#
# 
#   rotozip.corp:lwang[579] /export/content/build.qa.releases/R940/build-500_1_2296-prod $ cat ./security-auth-war/exploded-war/META-INF/config.properties
#   com.foobar.app.name=auth
#   com.foobar.app.version=0.0.500-RC1.2296
#   com.foobar.app.version.strict=0.0.500
#   com.foobar.app.version.qualifier=1.2296
#   com.foobar.app.env=${com.foobar.app.env}
#   com.foobar.app.machine=${com.foobar.app.machine}
#   com.foobar.app.instance=${com.foobar.app.instance}
#   extservices_path=${com.foobar.app.config.extservices}
#   override_path=${com.foobar.app.config.override}
#

  my $appname = shift;

  my $ccs_dirname;

  my $build_dir;

  # for xxx-tomcat, the key to build_dir_of hash should be xxx 
  # ... inconsistency, what a joy!
  if ( $appname =~ /-tomcat/ ) {
    my $tmp = $1 if $appname =~ /(.*)-tomcat/;
    $build_dir = "$build_dir_root/$release/$build_dir_of{$tmp}";
  }
  else {
    $build_dir = "$build_dir_root/$release/$build_dir_of{$appname}";
  }

  my $warname = $warname ? $warname : get_warname($appname);

  my $config_properties_file = "$build_dir/$warname/exploded-war/META-INF/config.properties";

  if ( -f "$config_properties_file" ) {

    open my $f, "<", $config_properties_file ;
    while (<$f>) {
      chomp;
      $ccs_dirname = $1 if m{^com.foobar.app.name=(.*)}x;
    }
    close $f;
   
  }
  print "\nbuild_dir: $build_dir" if $debug;
  print "\nconfig_properties_file: $config_properties_file\n" if $debug;


=pod

  open my $f, "<", $ccs_dirname_mapping_file or die "Cannot open file $ccs_dirname_mapping_file for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^#/;
    $ccs_dirname = $1 if m{(.*)\t\b$appname\E/}x;
  }
  close $f;

=cut

  $ccs_dirname ? $ccs_dirname : undef;

}


sub foobar {
#foobar
  
}

sub make_report_on_extra_keys_1 {

  my $ref_extras = shift;
  my @extras = @$ref_extras;

  print <<EOM;

##############################################################
#      
# The following keys are possibly extra. i.e., not needed
#	by the application
#  
##############################################################

EOM

  print join("\n", @extras);

  print "\n\n";

}

sub make_report_on_extra_keys {

  if ( keys %extra_keys ) {
    print <<EOM;

##############################################################
#
#  Possibly Extra Keys Report
#
#  Format:
#
# <component with possibly extra keys>:
#       <list of possibly extra keys>
#
##############################################################

EOM

    while (my ($k, $v) = each %extra_keys ) {
      print STDERR "$k:\n\t";
      print STDERR join("\n\t", @$v), "\n\n";
    }

  }
  else {

    print <<EOM;

##############################################################
#
#  Success! I did not find any extra properties!
#
##############################################################

EOM

  }


}


sub run_cmd {

  my $cmd = shift;

  system( $cmd );

  if ( $? == -1 ) {
    print "ERROR: failed to run $cmd. \n";
  } 
  elsif ( $? & 127 ) {
    printf "child proc died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? "with" : "without";
  }
  else {
    my $exit_value = $? >> 8;
    printf "child proc exited with value %d\n", $exit_value;
    print "Successfully ran $cmd\n" if $exit_value == 0;
  }

}


