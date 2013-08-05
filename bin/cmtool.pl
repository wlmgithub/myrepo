#!//bin/perl -w
#
#
# lwang:  cmtool 
#
#
#
use strict;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Utils qw( diff_of_A_and_B );

# ugly globals
my $ssh = "/bin/ssh";
my $grep = "/bin/grep";
my $ps = "/bin/ps";
my $cut = "/bin/cut";
my $awk = "/bin/awk";
my $sed = "/bin/sed";
my $cdc = "/export/content";
my $build_dir_root = "/export/content/build.qa.releases";
chomp( my $host_running_on = `hostname` );
if ( $host_running_on eq 'esv4-build01.corp' ) {
  $build_dir_root = "/export/content/releases";
}

chomp(my $timestamp = `date +%Y%m%d_%H%M%S`);


# get the options
my $action;
my $servicename;
my $machines;
my $excluded_machines;
my $command;
my $environment;
my $help;
my $oneliner;
my $debug;
my $pool;
my $this;
my $those;
my $file;
my $ppsearch_instance;
my $liar_member_search_instance;
my $release;

# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});


my %manifest;
my %machine_app_mapping;

GetOptions( 
	"action=s" => \$action,
	"servicename=s" => \$servicename,
	"environment=s" => \$environment,
	"machines=s" => \$machines,
	"excluded_machines=s" => \$excluded_machines,
	"command=s"  => \$command,
	"pool=s"  => \$pool,
	"this=s"  => \$this,
	"those=s"  => \$those,
	"file=s"  => \$file,
	"release=s"  => \$release,
	"ppsearch_instance=s"  => \$ppsearch_instance,
	"liar_member_search_instance=s"  => \$liar_member_search_instance,
	"oneliner"  => \$oneliner,
	"debug"  => \$debug,
	"help"  => \$help,
);

my $usage =<<USAGE;

Usage:

  $0 --action <action> --servicename <servicename> --environment <environment> --machines <machines> --command <command> --excluded_machines <excluded machines>
     --file <filename> --pool <pool_name> --this <machine> --those <machines>  --ppsearch_instance <inst>  --liar_member_search_instance <inst>  --debug --oneliner

-or-
 
  $0 -a <action> -s <servicename> -en <environment> -m <machines> -c <command> -ex <excluded machines>
     -f <filename>  -p <pool_name> -this <machine> -those <machines>  -ppsearch_instance <inst> -liar_member_search_instance <inst> -d  -o

Notes:
  * <action>: run_cmd | gethosts | genmanifests | compare_configs | get_pool_hosts | get_pools | get_machine_app_mapping |
              get_apps_machines_mapping | get_apps | get_wars | get_ccs_dirs | 
              get_ppsearch_instances | get_ppsearch_instance_hosts | get_ppsearch_instance_port  | 
              get_liar_member_search_instances | get_liar_member_search_instance_hosts | get_liar_member_search_port |

  * <amchines> and <excluded machines> should be a comma separated string or a space separated string, 
                                       e.g., "m1, m2,m3,    m4" or "m1 m2   m3       m4"
  * <environment>: prod or  stg.
  * <machines> and <environment> are mutually exclusive.
  * <pool_name> is actually app name.
  * --oneliner is used to show hosts on one line.
  * --this and --those or --pool are used for action compare_configs

USAGE

if ( $help ) {
  print $usage;
  exit;
}


# need action
if ( ! $action ) {
  print $usage;
  exit;
}

# action needs to match
if ( $action !~ m{
	run_cmd
	| gethosts
	| genmanifests
	| get_machine_app_mapping
	| compare_configs
	| get_pool_hosts
	| get_pools
	| get_apps
	| get_wars
	| get_ccs_dirs
	| get_ppsearch_instances
	| get_ppsearch_instance_hosts
	| get_ppsearch_instance_port
	| get_liar_member_search_instances
	| get_liar_member_search_instance_hosts
	| get_liar_member_search_instance_port
	| doit
      }xi ) {
  print $usage;
  exit;
}



########################## JUST DO IT

# TODO:

# do action: get_pools
if ( $action eq 'get_pools' ) {
  die "Please give me an environment name.\n" unless $environment;

  my $hosts_file="$itops_home/conf/hosts_${environment}_all";
  my @pools = get_pools($hosts_file);
  print join(" ", @pools);
  exit;
}




# do action:  get_pool_hosts
if ( $action eq 'get_pool_hosts' ) {
  die "Please give me a pool name and an environment name.\n" unless ($pool and $environment);
  my $ref_hosts = get_pool_hosts( $pool ); 
  print join(" ", @$ref_hosts);
  exit;
}


# do action: compare_configs
if ( $action eq 'compare_configs' ) {
    die "I need a pool name and an environment name  or --this and --those.\n" unless ( ($pool and $environment)  or ($this and $those));
    
    if ( $pool and $environment ) {
      die "Please give me a pool name.\n" unless $pool;
      # read manifest to get hosts for a pool
      # get pool hosts
      my $ref_pool_hosts = get_pool_hosts( $pool );
  
      # compare extservices.springconfig for pool_hosts
      compare_configs( $ref_pool_hosts );
    }
    elsif ( $this and $those ) {
      my @those_hosts = get_my_hosts();
      compare_configs_this_those( $this, \@those_hosts );
    }
    else {
      print $usage;
    }

    exit;
}


# do action: gethosts
if ( $action eq 'gethosts' ) {
  if ( ! $environment ) {
    die "Please use --environment to provide environment\n";
  } 
  else {
    my $hosts_file="$itops_home/conf/hosts_${environment}_all";
#    my @hosts = get_hosts($hosts_file);
    my @hosts = get_hosts($environment);

    if ( $oneliner ) {
      print join(" ", @hosts), "\n";
      exit;
    }
    else {
      print join("\n", @hosts), "\n";
      exit;
    }

  }
  exit;
}


# do action: genmanifests
if ( $action eq 'genmanifests' ) {

    need_either_env_or_machines();
    check_machine_and_env_mutuality();
    my @hosts = get_my_hosts();

    my @excluded_machines;
    if ( $excluded_machines ) {
      if ( $excluded_machines  =~ /,/ ) {
        @excluded_machines = split(/\s*,\s*/,  $excluded_machines);
      }
      else {
        @excluded_machines = split(/\s+/,  $excluded_machines);
      }
    }

    my $ref_diff = diff_of_A_and_B(\@hosts, \@excluded_machines);
    @hosts = @$ref_diff;

    # now that we have the hosts, we can go find apps
    #
    # create manifest first
    #
    # %manifest = (
    #   <app> => <array for machines running the app >,
    # );
    #

    for my $h ( @hosts ) {
#      print STDERR "\n=======$h===\n";
      print STDERR "$h===\r";


      #
      # 1st cmd is for catching apps in jetty container
      # 2nd cmd is for catching apps in tomcat container
      #
      #	test  -e  /export/content/app/i001/logs/catalina.pid  &&  cd  /export/content/app/i001/conf/private/default &&  ls -1 *.xml | $sed 's/\.xml//; s/\-context//'
      #
      # A better filtering technique might be:  ps -ef|grep app|grep java | grep -v grep | sed -e 's/.*-Dcom.foobar.app.name=\(.*\) -.*/\1/'
      #   but for the time being, let's use the exiting one
      #
      my $ssh_cmd = qq( 
	$ps -ef |  $grep app | $grep java | $grep -v grep | $grep -- '-Dcom.foobar.app.name' |  $sed -e 's/.*-Dcom.foobar.app.name=//' -e 's/ -D.*//' -e 's/ -cl.*//' ;
	test  -e  /export/content/app/i001/logs/catalina.pid  &&  cd  /export/content/app/i001/conf/public/default &&  ls -1 *.xml | $sed 's/\.xml//; s/\-context//' ;
      );

      my $cmd = qq( $ssh $h " $ssh_cmd " 2>/dev/null );
      my @apps = ` $cmd `; 

      for my $a ( @apps ) {
        chomp $a;

        #
        # SPECIAL CASE for 
        #              - seo (: dir )
        #              - external-tracking (: analytics )
        #              - leo (: tomcat-web)
        #
        if ( $a eq 'dir' ) {
          push @{$manifest{'seo'}}, $h;
        } elsif ( $a eq 'analytics' ) {
          push @{$manifest{'external-tracking'}}, $h;
        } elsif ( $a eq 'tomcat-web' ) {
          push @{$manifest{'leo'}}, $h;
        } else {
          push @{$manifest{$a}}, $h;
        }
      }

    }

    #
    # SPECIAL CASE for 
    #              - leocs ( VERY SPECIAL CASE !!! )
    #
    #
    if ( $environment eq 'prod' ) {
      push @{$manifest{'leocs'}}, 'cst01.prod';
    }

    if ( $environment eq 'stg' ) {
      push @{$manifest{'leocs'}}, 'esv4-fe06.stg';
    }


=pod

    # to find out apps in jetty container
    for my $h ( @hosts ) {
print STDERR "\n=======$h (jetty)===\n";
#      my @apps = ` $ssh $h $ssh_cmd `;
      my $ssh_cmd = qq( $ps -ef |  $grep app | $grep java | $grep -v grep | $grep -- '-Dcom.foobar.app.name' |  $sed -e 's/.*-Dcom.foobar.app.name=//' -e 's/ -D.*//' );
      my $cmd = qq( $ssh $h " $ssh_cmd " 2>/dev/null );
      my @apps = ` $cmd `;

      for my $a ( @apps ) {
        chomp $a;
        if ( $a ) {
          push @{$manifest{$a}}, $h;
        } 
      }
    }
    
    # to find out apps in  tomcat container
    for my $h ( @hosts ) {
print STDERR "\n=======$h (tomcat)===\n";
#
# ssh dbr01.prod " cd /export/content/app/i001/conf/public/default &&  ls -1 *.xml | sed 's/\.xml//'  " 2>/dev/null
#
      my $ssh_cmd = qq( cd  /export/content/app/i001/conf/public/default &&  ls -1 *.xml | $sed 's/\.xml//; s/\-context//' );
      my $cmd = qq( $ssh $h " $ssh_cmd " 2>/dev/null );
      my @apps = ` $cmd `;

      for my $a ( @apps ) {
#        chomp $a;
#        if ( $a ) {
          #
          # SPECIAL CASES for: seo, leo, external-tracking
          #
#          if ( $a eq 'dir' ) {
#            push @{$manifest{'seo'}},  $h;
#          } elsif ( $a eq 'tomcat-web' ) {
#            push @{$manifest{'leo'}},  $h;
#          } elsif ( $a eq 'analytics' ) {
#            push @{$manifest{'external-tracking'}},  $h;
#          } else { 
#            push @{$manifest{$a}},  $h;
#          }
#        }
      }
    }

=cut

  my $manifest_file;
  if ( $environment ) {
    $manifest_file = "/tmp/manifest_${environment}_${timestamp}.txt";   # put it in tmp for now
  }
  else {
    $manifest_file = "/tmp/manifest_adhoc_${timestamp}.txt";   # put it in tmp for now
  }

  # write the manifest into the manifest_file
  open my $mfh, ">", "$manifest_file" or die "Cannot open $manifest_file for writing: $!\n";
#  print Dumper(%manifest);
  for my $app ( sort keys %manifest ) {
#    print  "$app\t", join(" ", sort @{$manifest{$app}}), "\n";
    print $mfh "$app\t", join(" ", sort @{$manifest{$app}}), "\n";
  }
  close $mfh;

  # diff the  referece manifest with the generated one
  my $reference_manifest = "$FindBin::Bin/../manif/manifest_${environment}"; # this is used as a "should-be" reference for checking
  my $cmd = "diff  $reference_manifest $manifest_file";
  print "\n===== $cmd \n";
  system( $cmd ); # who cares about the stat?

  exit;
}

# do action: get_machine_app_mapping
if ( $action eq 'get_machine_app_mapping' or $action eq 'get_apps_machines_mapping' ) {

    need_either_env_or_machines();
    check_machine_and_env_mutuality();
    my @hosts = get_my_hosts();

    my @excluded_machines;
    if ( $excluded_machines ) {
      if ( $excluded_machines  =~ /,/ ) {
        @excluded_machines = split(/\s*,\s*/,  $excluded_machines);
      }
      else {
        @excluded_machines = split(/\s+/,  $excluded_machines);
      }
    }

    my $ref_diff = diff_of_A_and_B(\@hosts, \@excluded_machines);
    @hosts = @$ref_diff;


    for my $h ( @hosts ) {
      if ( $action eq 'get_apps_machines_mapping' ) {
        print STDERR ".";
      }
      else {
        print STDERR "$h===\r";
      }
      #
      # 1st cmd is for catching apps in jetty container
      # 2nd cmd is for catching apps in tomcat container
      #
      #  test  -e  /export/content/app/i001/logs/catalina.pid  &&  cd  /export/content/app/i001/conf/private/default &&  ls -1 *.xml | $sed 's/\.xml//; s/\-context//'
      #
      my $ssh_cmd = qq(
        $ps -ef |  $grep app | $grep java | $grep -v grep | $grep -- '-Dcom.foobar.app.name' |  $sed -e 's/.*-Dcom.foobar.app.name=//' -e 's/ -D.*//' -e 's/ -cla.*//'  -e 's/ -server.*//' -e s'/ -//'  ;
        test  -e  /export/content/app/i001/logs/catalina.pid  &&  cd  /export/content/app/i001/conf/public/default &&  ls -1 *.xml | $sed 's/\.xml//; s/\-context//' ;
      );

      my $cmd = qq( $ssh $h " $ssh_cmd " 2>/dev/null );
#print "\n$cmd\n";
      my @apps = ` $cmd `;

      # SPECIAL CASE for cst01.prod
      if ($h eq 'cst01.prod' || $h eq 'esv4-fe06.stg' ) {
#        print "$h: \n leocs\n";
        push @{$machine_app_mapping{$h}}, 'leocs';
      }

      foreach my $app ( @apps ) {
        chomp($app);
        if ( $app eq 'dir' ) { # SPECIAL CASE for seo
          push @{$machine_app_mapping{$h}}, 'seo' ;
        }
        elsif ( $app eq 'analytics' ) {  # SPECIAL CASE for external-tracking
          push @{$machine_app_mapping{$h}}, 'external-tracking';
        }
        elsif ( $app eq 'tomcat-web' ) {  # SPECIAL CASE for leo
          push @{$machine_app_mapping{$h}}, 'leo';
        }
        else { # normal cases
#          print "$h: \n $app\n";
          push @{$machine_app_mapping{$h}},  $app;
        }
      }
    }

#  print "@hosts\n";
#  print "\nBefore dumper...\n";
#  print Dumper($machine_app_mapping{'ss01.prod'});
#  print Dumper(%machine_app_mapping);


  my $machine_app_mapping_file;
  if ( $environment ) {
    $machine_app_mapping_file = "/tmp/machine_app_mapping_${environment}_${timestamp}.txt";   # put it in tmp for now
  }
  else {
    $machine_app_mapping_file = "/tmp/machine_app_mapping_adhoc_${timestamp}.txt";   # put it in tmp for now
  }

  open my $mfh, ">", "$machine_app_mapping_file" or die "Cannot open $machine_app_mapping_file for writing: $!\n";
  for my $h ( sort keys %machine_app_mapping ) {
#    print  "$h\t", join(" ", sort @{$machine_app_mapping{$h}}), "\n";
    print $mfh "$h\t", join(" ", sort @{$machine_app_mapping{$h}}), "\n";
  }
  close $mfh;

  # print the diff if action != get_apps_machines_mapping or action = get_apps_machines_mapping and in debug mode
  if  (   $action ne 'get_apps_machines_mapping'  or (  $action eq 'get_apps_machines_mapping' and $debug ) ) {

    # diff the  referece manifest with the generated one
    my $reference_file = "$FindBin::Bin/../manif/machine_app_mapping_${environment}"; # this is used as a "should-be" reference for checking
    my $cmd = "diff  $reference_file $machine_app_mapping_file";
    print "\n===== $cmd\n";
    system( $cmd ); # who cares about the stat?
  
  }


  if (  $action eq 'get_apps_machines_mapping' ) {
    #
    # Generate a mapping: <app groups> ==> <machine groups> 
    #
    my %hash;
    
    open my $f, "<", $machine_app_mapping_file or die "cannot open file $machine_app_mapping_file: $!\n";
    
    while (<$f>) {
      chomp;
      push @{$hash{$2}}, $1 if /(.*)\t(.*)/;
    }
    
    close $f;
    
    #print Dumper %hash;
  
    print "\n\n======== App(s) ==>  Machine(s) =======\n\n";
    
    for my $k ( keys %hash ) {
      print "$k ==>  @{$hash{$k}}\n";
    }
  }


  exit;
}


# do action: run_cmd
if ( $action eq 'run_cmd' ) {

  need_either_env_or_machines(); 
  check_machine_and_env_mutuality();
  my @hosts = get_my_hosts();
  do_run_cmd(\@hosts);

}


# do action: get_apps
if ( $action eq 'get_apps' ) {

  chomp(  my $host_running_on = `hostname` ) ;
  
  die "you'd better run this on esv4-build01.corp.\n" unless $host_running_on eq 'esv4-build01.corp';

  my @ccsdirs;

  if ( $servicename ) {
    push @ccsdirs, $servicename;
  }
  else {

    die "I need --servicename or --file <file> with ccs dirnames.\n" unless $file;
    die "I cannot open file $file.\n" unless -e $file;

    open my $f, "<", $file;
    while (<$f>) {
      chomp;
      push @ccsdirs, $_;
    }
  }

  print "@ccsdirs\n" if $debug;

  die "I need a release: --release <release>. \n" unless $release;


  for my $c ( @ccsdirs ) {
    get_app_of_ccsdir( $c , $release );
  }

=pod
  my @warnames;

  my %app_of_war = get_warname_to_app_mapping();

  die "I need a file with warname. \n" unless  $file;
  die "I cannot open file $file.\n" unless -e $file;

  open my $f, "<", $file;
  while (<$f>) {
    chomp;
    if ( exists $app_of_war{$_} )  {
      print $app_of_war{$_}, "\n";
    }
    else {
      print "Oops... cannot find app for $_\n";
    }
  }
  
#    @warnames = <$f>;
  close $f;

#  print join("", @warnames);
=cut


}

# do action: get_wars
if ( $action eq 'get_wars' ) {

  my @apps_in_file;

  if ( $servicename ) {
    push @apps_in_file, $servicename;
  }
  else { 
    die "I need a file with app names.\n" unless $file;
    open my $f, "<", $file or die "cannot open file $file for reading: $!\n";
    while (<$f>) {
      chomp;
      s/\s+$//;
      push @apps_in_file, $_;
    }
    close $f;
  
  }
  die "I need a release.\n" unless $release;



  my $legacy_bom_file = "$build_dir_root/$release/LEGACY-MASTER.BOM";
  my $build_bom_file = "$build_dir_root/$release/BUILD.BOM";  # for getting warname mapping

  for my $a ( @apps_in_file ) {
    my $warname = get_warname_of_app( $a, $build_bom_file);
    print STDERR "Oops... could not find warname for $a.\n" unless $warname;
    print "$warname\n";
  
  }

}

# do action: get_ccs_dirs
if ( $action eq 'get_ccs_dirs' ) {

  my @ccs_dirnames;
  my @apps_in_file;

  if ( $servicename ) {
    push @apps_in_file, $servicename;
  }
  else {

    die "I need --servicename or a file with app names.\n" unless $file;

    open my $f, "<", $file or die "cannot open file $file for reading: $!\n";
    while (<$f>) {
      chomp;
      s/\s+$//;
      push @apps_in_file, $_;
    }
    close $f;

  }

  die "I need a release.\n" unless $release;
  die "I need an environment. \n" unless $environment;


  my $legacy_bom_file = "$build_dir_root/$release/LEGACY-MASTER.BOM";
  my $build_bom_file = "$build_dir_root/$release/BUILD.BOM";  # for getting warname mapping
  my $release_bom_file = "$build_dir_root/$release/RELEASE.BOM";  # for getting war

  # future thinking here....
  # build a mega-hash
  # app => build# => warname => ccs_dirname
  #my %megahash;

#  my $build_num  = get_build_num_of_app( 'auth-server' , $legacy_bom_file);
#  my $warname = get_warname_of_app( 'auth-server', $build_bom_file);
#  my $ccsdir = get_ccs_dirname_of_app( 'jobs-server', $release, $legacy_bom_file, $build_bom_file);

#  print "$ccsdir\n";
#  exit;

  my %ccs_dirname_of_app;

  for my $a ( @apps_in_file ) {

    my $ccsdir = get_ccs_dirname_of_app( $a, $release, $legacy_bom_file, $build_bom_file, $release_bom_file);
    $ccs_dirname_of_app{$a} = $ccsdir if $ccsdir;

  }
  
  @ccs_dirnames = values %ccs_dirname_of_app;
 
  if ( $oneliner ) {
    print "@ccs_dirnames\n";
  }
  else {
    print join("\n", @ccs_dirnames), "\n";
  }

}


# do action: get_ppsearch_instances
if ( $action eq 'get_ppsearch_instances' ) {

  die  "I need an env.\n" unless $environment;

  my $file = get_app_container_mapping_file();

  print "app_container_mapping_file: $file\n" if $debug;

# format: peopleSearchService  people-search/i001 people-search/i002 people-search/i003 people-search/i004 people-search/i005 people-search/i006 people-search/i007 people-search/i008 people-search/i009 people-search/i010 people-search/i011 people-search/i012

  my @instances;
  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    s/\s+$//;
    next if /^#/;
    @instances = split(/\s+/, $1) if /^peopleSearchService\t(.*)/;
  }
  close $f;

  print join("\n", @instances);

}

# do action: get_ppsearch_instance_hosts
if ( $action eq 'get_ppsearch_instance_hosts' ) {

  die "I need a people search instance and an env." unless $ppsearch_instance && $environment;
  my $file = get_container_hosts_mapping_file();
  print "container_hosts_mapping_file: $file\n" if $debug;

  my @hosts;
  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    s/\s+$//;
    next if /^#/;
    @hosts = split(/\s+/, $1) if m{^$ppsearch_instance\t(.*)};
  }
  close $f;

  if ( @hosts ) {
    print join("\n", @hosts);
  }
  else {
    print STDERR "WARNING: I do not find any hosts for $ppsearch_instance.\n";
  }
}

# do action: get_ppsearch_instance_port
if ( $action eq 'get_ppsearch_instance_port' ) {
  
  die "I need a people search instance and an env." unless $ppsearch_instance && $environment;
  my $file = get_container_port_mapping_file();
  print "container_port_mapping_file: $file\n" if $debug;

  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    s/\s+$//;
    next if /^#/;
    print "$1\n" if /^$ppsearch_instance\t(.*)/;
  }
  close $f;

}

# do action: get_liar_member_search_instances
if ( $action eq 'get_liar_member_search_instances' ) {

  die  "I need an env.\n" unless $environment;

  my $file = get_app_container_mapping_file();

  print "app_container_mapping_file: $file\n" if $debug;

  my @instances;
  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    s/\s+$//;
    next if /^#/;
    @instances = split(/\s+/, $1) if /^liar-member-search\t(.*)/;
  }
  close $f;

  print join("\n", @instances);

}

# do action: get_liar_member_search_instance_hosts
if ( $action eq 'get_liar_member_search_instance_hosts' ) {

  die "I need a liar-member-search  instance and an env." unless $liar_member_search_instance && $environment;
  my $file = get_container_hosts_mapping_file();
  print "container_hosts_mapping_file: $file\n" if $debug;

  my @hosts;
  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    s/\s+$//;
    next if /^#/;
    @hosts = split(/\s+/, $1) if m{^$liar_member_search_instance\t(.*)};
  }
  close $f;

  if ( @hosts ) {
    print join("\n", @hosts);
  }
  else {
    print STDERR "WARNING: I do not find any hosts for $liar_member_search_instance.\n";
  }
}

# do action: get_liar_member_search_instance_port
if ( $action eq 'get_liar_member_search_instance_port' ) {
  
  die "I need a people search instance and an env." unless $liar_member_search_instance && $environment;
  my $file = get_container_port_mapping_file();
  print "container_port_mapping_file: $file\n" if $debug;

  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    s/\s+$//;
    next if /^#/;
    print "$1\n" if /^$liar_member_search_instance\t(.*)/;
  }
  close $f;

}


############################################################
########## subs
############################################################

sub get_ccs_dirname_of_app {

  my $app = shift;
  my $release = shift;

  my $legacy_bom_file = shift;
  my $build_bom_file = shift;
  my $release_bom_file = shift;

#  my $build_num =  get_build_num_of_app( $app, $legacy_bom_file);
  my $build_num =  get_build_num_of_app( $app, $release_bom_file );
  unless ( $build_num ) {
    print STDERR "Oops... could not find build number for $app.\n";
    return;
  }

#  my $warname = get_warname_of_app( $app, $build_bom_file);
  my $warname = get_warname_of_app( $app );
  print STDERR "Oops... could not find warname for $app.\n" unless $warname;
  
  return unless $warname; # no need to continue if no war found
  
  my $config_properties_file = "$build_dir_root/$release/$build_num/$warname/exploded-war/META-INF/config.properties";
  
  my $ccs_dirname ;
  if ( -f "$config_properties_file" ) {

    open my $f, "<", $config_properties_file ;
    while (<$f>) {
      chomp;
      $ccs_dirname = $1 if m{^com.foobar.app.name=(.*)}x;
    }
    close $f;
   
  }

  return $ccs_dirname  if $ccs_dirname ;
  return;
#    print STDERR "Oops... could not find ccs dirname for $app.\n";

}

### TOTO


sub get_app_of_ccsdir {

#esv4-build01.corp:lwang[571] /export/content/releases/R1032 $ grep profile-svcs   */*/*/*/config.properties
#build-521_8_3697-prod/profile-services-war/exploded-war/META-INF/config.properties:com.foobar.app.name=profile-svcs
#esv4-build01.corp:lwang[572] /export/content/releases/R1032 $ grep profile-services-war BUILD.BOM 
#profile-services-war=profile-services

  my $ccsdir = shift;
  my $release = shift;

  my $build_bom_file = "$build_dir_root/$release/BUILD.BOM";

  print "$build_bom_file\n" if $debug ;

#  my $config_properties_file = "$build_dir_root/$release/$build_num/$warname/exploded-war/META-INF/config.properties";

  chomp( my $theline = `cd $build_dir_root/$release; egrep "=$ccsdir\$"   */*/*/*/config.properties` );

  unless ( $theline ) {
    warn  "Ooops, I cannot find app for ccs dirname $ccsdir\n";
    return;
  }
  print "$theline\n" if $debug;

  my $war;

  if ( $theline =~ m{.*?/(.*?)/exploded-war/META-INF/config.properties:com.foobar.app.name=(?:$ccsdir)} ) {
    $war = $1;
  }
  
  print "war of $ccsdir: $war\n" if $debug;

  my $app;
  open my $f, "<", $build_bom_file or die "cannot open file: $build_bom_file: $!\n";
  while (<$f>) {
    chomp;
    $app = $1 if /^$war=(.*)/ ;
  }
  close $f;

  unless ( $app ) {
    print STDERR "Ooops, I cannot find app for  ccs dirname $ccsdir\n";
  }
  else {
    print "$app\n";
  }


}



sub get_warname_of_app {

  my $appname = shift;
  my $warname;

  my @wars = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $environment --getwar $appname | grep -v 'At revision' `;

  if ( @wars > 1 ) {
    @wars = grep { !/static-common/ } @wars;
  } 
  
  chomp(  $warname = pop @wars );

  return $warname ;

}

sub get_warname_of_app_00 {

  my $app = shift;
  my $build_bom_file = shift;

  my $warname;

  open my $f, "<", $build_bom_file or die "Cannot open $build_bom_file for reading: $!\n";

  while (<$f>) {
    chomp;
    next if /^#/;
    $warname = $1 if /(.*)=\b$app$/;    
  }
  close $f;

  return $warname ? $warname : undef;

}


sub get_build_num_of_app {

  my $app = shift;
  my $release_bom_file = shift;

  my $warname = get_warname_of_app( $app );
  print STDERR "Oops... could not find warname for $app.\n" unless $warname;

  if ( $warname ) {

    print "warname: =====$warname=====\n"  if $debug;
  
  
    open my $f, "<", $release_bom_file or die "cannot open $release_bom_file: $!\n";
    while ( <$f> ) {
  #99999
      chomp;
      if ( /^$warname=.*\|(.*)/ ) {   # leocs-war=com.foobar.network.leocs|leocs-war|0.0.523-RC3.3756
        my $last_str = $1;   # last_str = 0.0.523-RC3.3756
        return "build-${1}_${2}_${3}-prod"   if $last_str =~ m{0.0.(\d+)-RC(\d+).(\d+)};  # build-523_3_3756-prod
      }
    }
    close $f;
  
  }
  
  return;

}


sub get_app_container_mapping_file {
  my $app_container_mapping_file = "$itops_home/mappings/app_container_${environment}";
  return $app_container_mapping_file;
}

sub get_container_hosts_mapping_file {
  my $container_hosts_mapping_file = "$itops_home/mappings/container_hosts_${environment}";
  return $container_hosts_mapping_file;
}

sub get_container_port_mapping_file {
  my $container_port_mapping_file = "$itops_home/mappings/container_port_${environment}";
  return $container_port_mapping_file;
}


sub get_app_to_ccs_dirname_mapping {


}


sub get_app_to_ccs_dirname_mapping_v1 {

  my %hash;

  my $app_ccs_dirname_file = "$itops_home/manif/app_ccs_dirname";
  my $app_name_file = "$itops_home/manif/app_name";

  # entries in app_ccs_dirname_file should override entries in app_name_file
  my $f;
  open  $f, "<", $app_name_file;
  while (<$f>) {
    chomp;
    next if /^#/;
    next if /^\s+$/;
    $hash{$1} = $2 if /(.*)\t(.*)/; 
  }
  close $f;

  open  $f, "<", $app_ccs_dirname_file;
  while (<$f>) {
    chomp;
    next if /^#/;
    next if /^\s+$/;
    $hash{$1} = $2 if /(.*)\t(.*)/; 
  }
  close $f;
 
  return %hash;
}

sub get_warname_to_app_mapping {

  my %hash;

  my $app_name_file = "$itops_home/manif/app_name";
  open my $f, "<", $app_name_file or die "cannot open file $app_name_file for reading: $!\n";
  while (<$f>) {
    next if /^#/;
    next if /^\s+$/;
    $hash{$2} = $1 if /(.*)\t(.*)/;
  }
  close $f;

  return %hash;

}



sub do_run_cmd {
  my $ref_hosts = shift;
  # need command
  die "Please give me a command.\n" unless $command;

  # now do sth for each machine
  my $cmd = "$ssh";
  # my $cmd = qq( $ssh $h "$grep_cmd_be ");

  for my $h ( @$ref_hosts ) {
    my $cmd = qq( $ssh $h " $command " 2>/dev/null );
    print "\nRunning for $h the command: $cmd\n";
    run_me ( $cmd );
  }
}


sub get_hosts {
  my $env = shift;
   
#  my $file = shift;
  my @hosts;
#  @hosts = `ruby -e '\$LOAD_PATH.push ENV["ITOPS_HOME"] + "/lib/ruby"; require "mycm"; puts MYCM.get_hosts_of("$env", "array") ' `;
  @hosts = ` $itops_home/glu/bin/gen_manif_from_glu.rb  -e $env --gethosts | grep -v 'At revision' `;

  chomp(@hosts);

=pod

  open my $f, "<", $file or die "cannot open $file for reading: $!\n";
    while (<$f>) {
      chomp;
      push @hosts, $_;
    }
  close $f;

=cut

  @hosts;
}

sub run_me {
  my $cmd = shift;
  my $status = system( $cmd );
  if ( $status ) {
    print "********** WARNING: encountered problem running $cmd\n\n";
  }
}

sub compare_configs {
  my $ref_hosts = shift;
  my $cmd = "$FindBin::Bin/compare_configs @$ref_hosts ";
  system( $cmd );
}

sub compare_configs_this_those {
  my $this = shift;
  my $ref_those_hosts = shift;
  my $cmd = "$FindBin::Bin/compare_configs $this @$ref_those_hosts ";
  system( $cmd );
}

sub get_pool_hosts {
  my $pool = shift;

  my @pool_hosts = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $environment --svc $pool  | grep -v 'At revision' `;
  chomp(@pool_hosts);
  \@pool_hosts;
=pod
  my $reference_manifest = "$FindBin::Bin/../manif/manifest_${environment}"; # this is used as a "should-be" reference for checking
  my @pool_hosts;
  # read manifest to get hosts for a pool
#      print "$reference_manifest\n";
  open my $mf, "<", $reference_manifest or die "cannot open file: $reference_manifest: $!\n";
  while ( <$mf> ) {
    chomp;
    if ( /^$pool\t(.*)/ ) {
      @pool_hosts = split(/;/, $1);
    }
  }
  close $mf;
#      print "@pool_hosts\n";

  return \@pool_hosts;
=cut

}


sub get_pools {

  my @pools =  `$itops_home/glu/bin/gen_manif_from_glu.rb --env $environment --getsvcs  | grep -v 'At revision' `;
  chomp(@pools);

=pod
  my $reference_manifest = "$FindBin::Bin/../manif/manifest_${environment}"; # this is used as a "should-be" reference for checking
  # read manifest to get pools
  my @pools;
  open my $mf, "<", $reference_manifest or die "cannot open file: $reference_manifest: $!\n";
  while ( <$mf> ) {
    chomp;
    if ( /^(.*)\t.*/ ) {
      push @pools,  $1;
    }
  }
  close $mf;
=cut

  @pools;

}


sub check_machine_and_env_mutuality {
  #
  # environment
  #
  # machines and environment should be mutually exclusive
  #   
  if ( ( ! $machines &&  ! $environment ) or
       ( $machines &&  $environment ) 
     ) {
  #  print $usage;
    print "Oops: machines and environment are mutually exclusive.\n";
    exit;
  }
}


sub get_my_hosts {
  #
  # machines
  #
  my @hosts;
  if (  $machines ) {
    if ( $machines =~ /,/ ) {
      @hosts = split(/\s*,\s*/, $machines);
    }
    else {
      @hosts = split(/\s+/, $machines);
    }
  } 
  elsif ( $those ) {
    if ( $those =~ /,/ ) {
      @hosts = split(/\s*,\s*/, $those);
    }
    else {
      @hosts = split(/\s+/, $those);
    }
  }
  else {
    if ( $environment ) {
      my $hosts_file="$itops_home/conf/hosts_${environment}_all";
#      @hosts = get_hosts($hosts_file);
      @hosts = get_hosts($environment);
    }
  }
  
  if ( $debug ) {
    print "\$action = $action\n";
    print "\$environment = $environment\n" if $environment;
    print "\@hosts = @hosts\n";
    print "\$command = $command\n";
  }

  return @hosts;
}

sub need_either_env_or_machines {
    die "Need either --environment or --machines.\n" unless ($environment or $machines);
}


############################################################
__END__

