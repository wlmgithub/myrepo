#!/bin/env perl 
#
# lwang: Fetch public_access log from the first machine for one app or all apps ( --app | -a  <appname> ) 
#
# usage:
#
#	 ./fetcher.pl  
#  -or- 
#	 ./fetcher.pl  -help
#

use warnings;
use strict;

use lib '../../lib/perl';
use MYCM;

use Getopt::Long;

use POSIX 'WNOHANG';
$SIG{CHLD} = sub { while( waitpid(-1, WNOHANG)  > 0 ) { } };

my $help;
my $debug;
my $app;
my $execute;
my $start;	# start time stamp
my $end;	# end time stamp
my $parallel;	# parallel degree
my $file;	# file containing apps interested
my $perl = -e "/bin/perl" ? "/bin/perl" : "/usr/local/bin/perl";
my $gtar = "/usr/sfw/bin/gtar";
my $ssh = -e "/bin/ssh" ? "/bin/ssh" : "/usr/bin/ssh";
my $scp = -e "/bin/scp" ? "/bin/scp -C " : "/usr/bin/scp -C ";
my $env;
my $outdir;	# where you want to put the logs
my $user;	# do ssh as user, otherwise as whoever runs the scr 
my $allmachines;	# not just get the first machine, but all machines for an app 
my $noemail;		# do not send out email
my $reduced;		# only fetch _reduced_ public access log file
my $containerlog;       # get container log, rather than public_access log
my $gclog;              # get gc log, rather than public_access log

#####
my $perftest;		# drop on to perftest machines. 
			# NOTE: looks like it's no longer needed, since Hari has implemented a mechanism outside this script. 
			# 	But it's still interesting to pursue in this direction in the context of this script, but no hurry any more.

my $deft_parallel = 1;  	# default parallel degree

my $perftest_allocation_limit;	 	# this is the max number of log files each perftest machine is allocated, see later on the number, depending on switch $allmachines
my %perftest_allocation;		# this is the global hash to keep track of the number of allocated log files for each perftest machine:
					#	perftest_machine => count

# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});


GetOptions(
	"user=s" => \$user,
	"outdir=s" => \$outdir,
	"file=s" => \$file,
	"parallel=s" => \$parallel,
	"start=s" => \$start,
	"end=s" => \$end,
	"env=s" => \$env,
	"app=s" => \$app,
	"allmachines" => \$allmachines,
	"noemail" => \$noemail,
	"reduced" => \$reduced,
	"perftest" => \$perftest,
	"help" => \$help,
	"debug" => \$debug,
	"execute" => \$execute,
	"containerlog" => \$containerlog,
	"gclog" => \$gclog,
);

my $usage =<<USAGE;

Usage:

  $0 	{ [ --app | -a  <appname> ] | [ --file | -f <file> ]  } { --env | -env <env> } 
	{ --start <start time stamp> } {  --end <end time stamp> }  
	--outdir <output dir location> --parallel <parallel degree>  --user <user>
	--containerlog --gclog
	--allmachines --noemail  --reduced --debug --help --execute

Examples:

	\$  $0 --env ech3  --app auth-server --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --execute
		: fetch public_access log for auth-server only, in the time window specified, and put them in the default drop dir: Hari's public folder

	\$  $0 --env ech3  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --outdir ~/mylogs --execute
		: fetch public_access logs for all apps in manifest_ech3,  in the time window specified, and put them in ~/mylogs

	\$  $0 --env stg  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --outdir ~/mylogs --execute
		: fetch public_access logs for all apps in manifest_stg,  in the time window specified, and put them in ~/mylogs

	\$  $0 --env stg  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --outdir ~/mylogs --user lwang --execute
		: fetch public_access logs for all apps in manifest_stg,  in the time window specified, and put them in ~/mylogs, using credential of user lwang

	\$  $0 --env ech3  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --allmachines --parallel 10 --execute
		: fetch public_access logs for all apps in manifest_ech3 for all machines of each app in the time window specified, and put them in the default drop dir

	\$  $0 --env ech3  --app all --containerlog   --parallel 10  --execute
		: fetch container  logs for all apps in ech3 for the first machine  of each app,   and put them in the default drop dir

	\$  $0 --env ech3  --app all --containerlog   --allmachines --parallel 10  --execute
		: fetch container  logs for all apps in ech3 for all machines of each app,   and put them in the default drop dir

	\$  $0 --env ech3  --app all --gclog  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --allmachines --parallel 10  --execute
		: fetch gc  logs for all apps in ech3 for all machines of each app in the time window specified, and put them in the default drop dir



NOTES: 	* The minute part in the timestamp is ignored for now. e.g., -start '2009/11/02 07:05' -end '2009/11/02 14:18' is the same as -start '2009/11/02 07:00' -end '2009/11/02 14:00' 
          which means fetching lines with time from '2009/11/02 07:00' to '2009/11/02 14:59'

	* Default parallel degree is: $deft_parallel

	* Default <login_name> is whoever runs the script
	
	* By default, we only get the first machine, but --allmachines can be used to get all machines

	* --reduced is used to fetch only _reduced_ log, otherwise, both _reduced_ and _full_ logs will be fetched



USAGE


#if ( $help  or @ARGV == 0 ) {
if ( $help or ! ( $app || $file ) ) {
  print $usage;
  exit;
}


# if containerlog is given, no need to have $start and $end
if ( $containerlog ) {
  $start = '1';  
  $end = '2';
}

if ( ! $start || ! $end  || ! $env ) {
  print $usage;
  exit;
}

if ( $app and $file ) {
  print "\n--app and --file are mutually exclusive.\n";
  print $usage;
  exit;
}



$parallel = $parallel ? $parallel : $deft_parallel;  # give a default parallel degree: $deft_parallel 

print "parallel degree: $parallel\n" if $debug;


chomp (my $starttime = `date +%Y%m%d_%H%M%S` );

# globals
my $hari_public_folder    = "/Volumes/Staff/Mountain View/Haricharan Ramachandra/Public/log_fetching";
my $default_drop_dir_root = $hari_public_folder;
my $glu_dir = "/export/content/glu";


my $drop_dir_root = $outdir ? $outdir :  $default_drop_dir_root;

die "\nOops.... Please connect to server smb://dfs.foobar.biz and mount the volume \"Staff\" first. \n\n" unless -d "$drop_dir_root"; 

if ( $perftest ) {
  $drop_dir_root = "/export/home/tester/log_fetching";
}



# depending on the number of log files: as of now 2009/12/04,   
#	105 log files , if first_machine
#	558 log files , if allmachines

if ( $allmachines ) {
  $perftest_allocation_limit = 150;
}
else {
  $perftest_allocation_limit = 30;
}

my @perftest_machines = qw( 
  perftest7.qa
  perftest8.qa
  perftest9.qa
  perftest15.qa
);
  

for ( @perftest_machines  ) {
  $perftest_allocation{$_} = 0;
}


# now that we have the drop dir, mkdir a sub dir
chomp( my $me = `whoami`);
chomp( my $time_stamp = `date +%Y%m%d_%H%M%S`);
print "time_stamp: $time_stamp \n" if $debug;
print "me: $me \n" if $debug;
print "env: $env \n" if $debug;

my $runas = $user ? $user : $me;

my $work_dir = "${time_stamp}_${me}_${env}";

print "work_dir: $work_dir \n" if $debug;



if ( $perftest ) {

  umask 0022;
  mkdir "$hari_public_folder/$work_dir" if $execute;
  print "Creating $drop_dir_root on perftest machines: @perftest_machines. \n" if $debug;
  foreach my $m ( @perftest_machines ) {
    my $cmd = qq[$ssh tester\@$m "mkdir -p $drop_dir_root; rm -rf $drop_dir_root/*" ];
    do_cmd( $cmd );
  }

} 
else {

  #die "\nOops.... Please connect to server smb://dfs.foobar.biz and mount the volume \"Staff\" first. \n\n" unless -d "$drop_dir_root";
  die "\nOops.... I cannot find: $drop_dir_root, or it's not writable by you.  \n\n" unless -w "$drop_dir_root";

  umask 0022;
  mkdir "$drop_dir_root/$work_dir" if $execute;

}



# now get to work...



if ( $app &&  $app ne 'all'  ) {

    doit( $app );

#  my $m = get_first_machine( $app );
#  print STDERR "\nINFO: fetching log for $app on $m\n" if $debug ;
#  fetch_log( $app, $m);

  exit;

} 
elsif ( $file ) {

  my @apps;

  # if -file is provided, get all apps from the file
  print "Reading apps from file: $file...\n" if $debug; 

  open my $f, "<", $file or die "Cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^\s+$/;
    s/\s+$//;
    push @apps, $_;
  }
  close $f;

  print "Dealing apps: ===@apps===\n" if $debug;

  do_it_in_parallel( @apps );


}
else {

#  my $apps = `$itops_home/bin/cmtool.pl -a get_pools -env $env`;
#  my @apps = split(" ", $apps);

  chomp( my @apps = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $env  --getsvcs | grep -v 'At revision' ` ) ;
  
  
  do_it_in_parallel( @apps );

  
}


if ( $execute ) {
  send_email() unless $noemail;
}


exit(0);


sub do_it_in_parallel {

  my @apps = @_;

  if (  @apps < $parallel ) {
    do_chunk(  \@apps  );
  }
  else {

    my @chunks;  # array of refs to arrays: [ [...], [...] ... ]
    push @chunks, [ splice @apps, 0, $parallel ] while @apps;
  
    for my $chunk ( @chunks ) {
      print "\nDealing with chunk: @$chunk\n";
      print scalar @$chunk, "\n";
  
      do_chunk( $chunk ) ;
  
    }
  
  }

}

sub do_chunk {

  my $ref_chunk = shift;

  my @chunk = @$ref_chunk;

  my @childs;

  for ( 1..@chunk ) {
  
      my $pid = fork();
  
      if ($pid) {
  
        # parent
        push(@childs, $pid);
  
      } elsif ($pid == 0) {
  
        # child
        print "in child: $_ ( $chunk[$_-1] )\n\n";
        # sleep 5;
        doit( $chunk[$_-1] );
        exit(0);
  
      } else {
  
        die "couldn't fork: $!\n";
  
      }
  
  }
  
  foreach (@childs) {
    waitpid($_, 0);
  }
  
}

sub do_machines_in_parallel {
  my $app = shift;
  my $ref_machines = shift;

  my @machines = @$ref_machines;

  my @childs;

  foreach my $m ( @machines ) {
    my $pid = fork();
    if ( $pid ) {
      push @childs, $pid;
    }
    elsif ( $pid == 0 ) {
      print "in do_machines_in_parallel, doing $app on $m.\n";
      fetch_log( $app, $m );
      exit(0); 
    }
    else {
      die "couldn't fork in do_machines_in_parallel: $!\n";
    }
  }

  foreach ( @childs ) {
    waitpid($_, 0);
  }

}


sub doit {

  my $app = shift;

  return if $app =~ /^memcache/;

  if ( $allmachines ) {
    # do machines in parallel
    my @machines = get_all_machines_of( $app);
    do_machines_in_parallel($app, \@machines);

  }
  else {
    my $m = get_first_machine ( $app );

    print "\nINFO: fetching log for $app on $m\n" if $debug ;

    fetch_log( $app, $m);

  }
}


sub send_email {

  # send email when done
  # hramachandra@foobar.com
  # echo "/Volumes/Staff/Mountain View/Haricharan Ramachandra/Public/log_fetching/20091028_lwang/" | mailx -s "log download is done, please check ..." lwang@foobar.com
  
  chomp (my $endtime = `date +%Y%m%d_%H%M%S` );
  
  my $subject;
  if ( $containerlog ) { 
    $subject = "container log download is done, please check ...";
  }
  elsif ( $gclog ) {
    $subject = "gc log download is done, please check ...";
  }
  else {
    $subject = "public access log download is done, please check ...";
  }
  my $msg = "$drop_dir_root/$work_dir/\n\nStarting: $starttime\nEnding: $endtime\n" ;
  $msg .= "\n\n@perftest_machines\n" if $perftest;
  my $ccusers = "lwang\@foobar.com,siteops\@foobar.com";
  my $tousers = "bsridharan\@foobar.com hramachandra\@foobar.com es-performance\@foobar.com";
  
  #| mailx -s "$subject" -c lwang@foobar.com  lwang@foobar.com ];
  
  my $cmd = qq[ echo  "$msg" |  mailx -s "$subject" -c $ccusers $tousers ];
  
  print "Running: $cmd\n" if $debug;
  system( $cmd) if $execute;

}


sub get_all_machines_of  {
  my $app = shift;
#  my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $env -pool $app`;
#  my @hosts = split(" ", $hosts);
  chomp( my @hosts = `$itops_home/glu/bin/gen_manif_from_glu.rb  --env $env  --svc  $app --nosvn | grep -v 'At revision'  ` );

  @hosts;

}


sub get_first_machine {
  my $app = shift;
#  my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $env -pool $app`;
  my $hosts = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $env --svc  $app --nosvn | grep -v 'At revision' `;
  my @hosts = split(" ", $hosts);

  #
  # ugly special cases... yucky
  #
  if ( $app eq 'nus' && $env eq "ech3"  ) {
    'ech3-cdn31.prod';
  } 
  else {
    $hosts[0];
  }
}

# used to get $start_hour / $end_hour
# input: $start / $end
sub get_hour { 
  my $stamp = shift;
  my $hour;
  if ( $stamp =~ /.*\s+(.*):.*/ ) {
    $hour = $1;
  }

  return $hour;
}

sub fetch_hourly_log {

  my $logfile_orig = shift;
  my $m = shift;
  my $cmd;

  my $instance;
  my $logfile;

  print "\nlogfile_orig: $logfile_orig\n" if $debug;

  if ( $logfile_orig =~ m{.*/(i0\d{2})/logs/(.*)} ) {
    $instance = $1; 
    $logfile = $2;
  }
  else {
    return;
  }

  my $logfile_name = "${m}_${instance}_${logfile}";

  $cmd = qq[  $scp $runas\@$m:$logfile_orig "$drop_dir_root/$work_dir/$logfile_name" ];
  do_cmd ( $cmd );

}


sub get_contextpaths {

  my $a = shift;

  # cps: context paths
  chomp( my @cps = `$itops_home/glu/bin/gen_manif_from_glu.rb --env $env  --getcp $a  --nosvn ` ) ;

  return @cps;

}



sub fetch_log {
  my $a = shift;
  my $m = shift;

  my $p = get_path($a);

# /Users/lwang/code/itops/glu/bin $ ./gen_manif_from_glu.rb --env beta --getcp auth-server --nosvn

  my @cps;

  if ( $containerlog ) {

    @cps = get_contextpaths( $a );

    # special deal for FE: xxx-tomcat
    # stuck xxx in @cps if not in there yet
    if ( $a =~ m{(.*)-tomcat} ) {
      my $fe_prefix =  $1;
      push @cps, $fe_prefix  unless ( grep { $_ eq $fe_prefix  } @cps  ) ;
    }

  }
  elsif ( $gclog ) {
    push @cps, "gc";
  }

  print "\n\$p in fetch_log: $p\n" if $debug;
  print "\n\@cps in fetch_log: @cps \n" if $debug;

#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/conf/server_conf.sh  " 2>/dev/null ];
#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/logs/*public_access.log  " 2>/dev/null ];

  # it's possible that there exist  more than one public_access files 
  #chomp(my @logfile_path = `$ssh  $runas\@$m "ls -1 /export/content/$p/i0*/logs/*public_access.log" 2>/dev/null` );
#  chomp( my @logfile_path = `ssh  $m "if [ -e \"$glu_dir/apps/$p\" ]; then ls -1 $glu_dir/apps/$p/i0*/logs/*public_access.log; else ls -1 /export/content/$p/i0*/logs/*public_access.log; fi" 2>/dev/null ` );
#  chomp( my @logfile_path = `ssh  $m "if [ -e \"$glu_dir/apps/$p\" ]; then ls -1 $glu_dir/apps/$p/i0*/logs/*public_access.log*; else ls -1 /export/content/$p/i0*/logs/*public_access.log*; fi" 2>/dev/null ` );

  my @logfile_path;
  
  if ( @cps ) {

    for my $cp ( @cps ) {

      chomp( my @paths = `$ssh  $m "/bin/bash -c ' if [ -e \"$glu_dir/apps/$p\" ]; then ls -1 $glu_dir/apps/$p/i0*/logs/$cp.log; else ls -1 /export/content/$p/i0*/logs/$cp.log; fi' " 2>/dev/null ` );

      push @logfile_path, @paths;

#      print "\n99999999999: $glu_dir/apps/$p :  $glu_dir/apps/$p/i0*/logs/$cp.log  : @paths\n" if $debug;

    }

  }
  else {

    chomp( @logfile_path = `$ssh  $m "/bin/bash -c ' if [ -e \"$glu_dir/apps/$p\" ]; then ls -1 $glu_dir/apps/$p/i0*/logs/*public_access.log*; else ls -1 /export/content/$p/i0*/logs/*public_access.log*; fi' " 2>/dev/null ` );

  }

  # just print and return if nothing found... chance is almost nil now that we changed the pattern
  unless ( @logfile_path  ) {

    if ( $containerlog ) {
      print "\n****** No container log file found for $a on $m\n\n";
    }
    elsif ( $gclog ) {
      print "\n****** No gc log  file found for $a on $m\n\n";
    }
    else {
      print "\n****** No public_access file found for $a on $m\n\n";
    }
    return;

  }

  print "\n logfile_path in fetch_log:  @logfile_path \n" if $debug;

  # otherwise, do some real work...

  my $start_hour = get_hour($start);
  my $end_hour = get_hour($end);

  chomp( my $year = `date +%Y`);
  chomp( my $month = `date +%m`);
  chomp( my $day = `date +%d`);


  # two passes: first find out @hourly_logs, then deal with cases
  my @hourly_logs;

  for my $logfile_path ( @logfile_path ) {

    chomp($logfile_path);
    if ( $logfile_path =~ /.*(\d{4})-(\d{2})-(\d{2})-(\d{2}).gz/  ) {
  
      my $year_in_file = $1;
      my $month_in_file = $2;
      my $day_in_file = $3;
      my $hour_in_file = $4;
  
      for my $hour ( $start_hour .. $end_hour ) {
        if ( $hour eq $hour_in_file and $year eq $year_in_file and $month eq $month_in_file and $day eq $day_in_file ) {
          push @hourly_logs, $logfile_path;
        }
      }
  
    }

  }

  # if we have hourly_logs, handle them
  #   otherwise do the old way
  if ( @hourly_logs ) {

    for my $logfile ( @hourly_logs ) {

        print "found hourly logfile: $logfile\n" if $debug;

        fetch_hourly_log( $logfile, $m );

############ TODO: until we get to the point that hourly log files has _reduce_ / _full_ in the name, we do not differentiate
=pod
      if ( $reduced ) {
        fetch_hourly_log( $logfile, $m ) if $logfile =~ /_reduced_/;
      } 
      else {
        fetch_hourly_log( $logfile, $m );
      }
=cut

    }

  }
  else {

    if ( $containerlog ) {

      # fetch unfiltered file
      foreach my $logfile_path ( @logfile_path ) {
        fetch_whole_logfile( $logfile_path, $m );
      }

    }
    elsif ( $gclog ) {

      # fetch unfiltered file
      foreach my $logfile_path ( @logfile_path ) {
        fetch_whole_logfile_for_gc( $logfile_path, $m, $a );
      }

    }
    else {

    # get filtered log file

    foreach my $logfile_path ( @logfile_path ) {

      # handle with the old way ...
      if ( $logfile_path =~ /.*log$/ ) {

        # ... while taking into account _reduced_ or not
        if ( $reduced ) {
          fetch_filtered_logfile( $logfile_path, $m ) if $logfile_path =~ /_reduced_/;
        }
        else {
          fetch_filtered_logfile( $logfile_path, $m );
        }

      }

    }

    }

  }

=pod
  if ( @logfile_path  ) {

    # get filtered log file

    foreach my $logfile_path ( @logfile_path ) {

      # if hourly logs found, grab them ... 
      if ( $logfile_path =~ /.*(\d{4})-(\d{2})-(\d{2})-(\d{2}).gz/  ) {

      }
      else {

        # ... otherwise, fetch_filtered_logfile, while taking into account _reduced_ or not
        if ( $reduced ) {
          fetch_filtered_logfile( $logfile_path, $m ) if $logfile_path =~ /_reduced_/;
        }
        else {
          fetch_filtered_logfile( $logfile_path, $m );
        }

      }

    }

  }
  else {
    print "\n****** No public_access file found for $a on $m\n\n";
  }
=cut

}


sub get_path {
  my $a = shift;
  my $p = $a; # by default

#  system("./is_front_end_webapp $a");

#  if ( `egrep '^$a      ' $itops_home/manif/container_mapping_ech3` ) {
#chomp(    $p = `cat $itops_home/manif/container_mapping_ech3 | egrep '^$a        ' | cut -f2 `     ) ; 
#  }

  open my $f, "<", "$itops_home/manif/container_mapping_${env}" or die "Cannot open file $itops_home/manif/container_mapping_${env}: $!\n";
  while (<$f>) {
    chomp;
    $p = $1 if /^$a\t(.*)/;
  }
  close $f;

  $p;

}

sub fetch_whole_logfile_for_gc {
  my $logfile_orig = shift;
  my $m = shift;
  my $a = shift;
 
  my $cmd;
  my $instance;
  my $logfile;

  print "\nlogfile_orig: $logfile_orig\n" if $debug;

  if ( $logfile_orig =~ m{.*/(i0\d{2})/logs/(.*)} ) {
    $instance = $1;
    $logfile = $2;
  }
  else {
    return;
  }

  my $logfile_to_fetch_path = $1 if  $logfile_orig =~ m{(.*)/.*};

  my $logfile_to_fetch = "$logfile_to_fetch_path/$logfile";
  my $logfile_to_dest = "${m}_${instance}_${a}_${logfile}";

  print "logfile_to_fetch: $logfile_to_fetch\n" if $debug;
  print "logfile_to_dest: $logfile_to_dest\n" if $debug;
  print "$scp $runas\@$m:$logfile_to_fetch  $drop_dir_root/$work_dir/$logfile_to_dest\n" if $debug;


  $cmd = qq[ $scp $runas\@$m:$logfile_to_fetch  "$drop_dir_root/$work_dir/$logfile_to_dest" ];
  do_cmd( $cmd ) ;
  

}


sub fetch_whole_logfile {
  my $logfile_orig = shift;
  my $m = shift;
 
  my $cmd;
  my $instance;
  my $logfile;

  print "\nlogfile_orig: $logfile_orig\n" if $debug;

  if ( $logfile_orig =~ m{.*/(i0\d{2})/logs/(.*)} ) {
    $instance = $1;
    $logfile = $2;
  }
  else {
    return;
  }

  my $logfile_to_fetch_path = $1 if  $logfile_orig =~ m{(.*)/.*};

  my $logfile_to_fetch = "$logfile_to_fetch_path/$logfile";
  my $logfile_to_dest = "${m}_${instance}_${logfile}";

  print "logfile_to_fetch: $logfile_to_fetch\n" if $debug;
  print "logfile_to_dest: $logfile_to_dest\n" if $debug;
  print "$scp $runas\@$m:$logfile_to_fetch  $drop_dir_root/$work_dir/$logfile_to_dest\n" if $debug;


  $cmd = qq[ $scp $runas\@$m:$logfile_to_fetch  "$drop_dir_root/$work_dir/$logfile_to_dest" ];
  do_cmd( $cmd ) ;
  

}

sub fetch_filtered_logfile {

  my $logfile_orig = shift;
  my $m = shift;
  my $cmd;

  my $instance;
  my $logfile;

  print "\nlogfile_orig: $logfile_orig\n" if $debug;

  if ( $logfile_orig =~ m{.*/(i0\d{2})/logs/(.*)} ) {
    $instance = $1; 
    $logfile = $2;
  }
  else {
    return;
  }

#  my $logfile = $1 if $logfile_orig =~ m{.*/(.*)};
  my $logfile_filtered = "${m}_${instance}_${logfile}";
  my $logfile_filtered_tgz = "${m}_${instance}_${logfile}.tgz";

  # push the filter script to remote host
  $cmd = qq[ $scp filter.pl $runas\@$m:~  ];
  do_cmd ( $cmd );

  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; $perl filter.pl '$start' '$end'  $logfile_orig  $logfile_filtered " ];
  do_cmd ( $cmd );

  # gtar
  $cmd = qq[ $ssh -l $runas $m "cd ~; $gtar czf $logfile_filtered_tgz  $logfile_filtered"  ];
  do_cmd ( $cmd );

  # fetch the filtered logfile
  unless ( $perftest ) {
    $cmd = qq[ $scp $runas\@$m:~/$logfile_filtered_tgz  "$drop_dir_root/$work_dir/$logfile_filtered_tgz" ];
    do_cmd ( $cmd );

    # do not litter
    $cmd = qq[ $ssh -l  $runas $m "cd ~; rm $logfile_filtered_tgz $logfile_filtered" ];
    do_cmd ( $cmd );
  }
  else {
    # if we are asked to drop to pertest machines...
    # 
    # Current implementation: 
    #   use a global hash to keep track of how many logs have been allocated to which perftest machine
    # 
    while ( my $pm  = pop @perftest_machines ) {
      if ( $perftest_allocation{$pm} < $perftest_allocation_limit ) {
        print "inc on $pm \n" if $debug;
        # 
        # !!!!! ALERT !!!!! 
        # 
        # TODO: 
        # 
        # 
        #  there is an issue with scp directly from prod machine to perftest machine
        #  so we are doing  2 step scp now: first from prod box to hari_public_folder, then from hari_public_folder to perftest box
        # 

        # step 1: scp from prod box to hari_public_folder
        #
        $cmd = qq[ $scp $runas\@$m:~/$logfile_filtered_tgz  "$hari_public_folder/$work_dir/$logfile_filtered_tgz" ];
        do_cmd ( $cmd );

        # step 2: scp from hari_public_folder to perftest box
        #
        $cmd = qq[ $scp  "$hari_public_folder/$work_dir/$logfile_filtered_tgz"  tester\@$pm:$drop_dir_root/$logfile_filtered_tgz ];
        do_cmd ( $cmd );

        $perftest_allocation{$pm}++; 
        last;
      } 
      else {
        next;
      }
    }

  }

}

sub do_cmd {
  my $cmd = shift;

  print $cmd, "\n" if $debug;
  system( $cmd ) if $execute;

}



