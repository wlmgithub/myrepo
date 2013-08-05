#!/bin/env perl 
#
# lwang: gc.log fetcher, adapted from fetcher.pl for log_fetching project
#
#
# usage:
#
#	 ./fetcher.pl  
#  -or- 
#	 ./fetcher.pl  -help
#

use warnings;
use strict;

use Getopt::Long;

use POSIX 'WNOHANG';
$SIG{CHLD} = sub { while( waitpid(-1, WNOHANG)  > 0 ) { } };

my $help;
my $debug;
my $app;
my $execute;
my $parallel;	# parallel degree
my $file;	# file containing apps interested
my $perl = "/bin/perl";
my $gtar = "/usr/sfw/bin/gtar";
my $ssh = "/bin/ssh";
my $scp = "/bin/scp";
my $env;
my $outdir;	# where you want to put the logs
my $user;	# do ssh as user, otherwise as whoever runs the scr 
my $allmachines;	# not just get the first machine, but all machines for an app 
my $noemail;		# do not send out email

my $deft_parallel = 1;  	# default parallel degree


# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});


GetOptions(
	"user=s" => \$user,
	"outdir=s" => \$outdir,
	"file=s" => \$file,
	"parallel=s" => \$parallel,
	"env=s" => \$env,
	"app=s" => \$app,
	"allmachines" => \$allmachines,
	"noemail" => \$noemail,
	"help" => \$help,
	"debug" => \$debug,
	"execute" => \$execute,
);

my $usage =<<USAGE;

Usage:

  $0 	{ [ --app | -a  <appname> ] | [ --file | -f <file> ]  } { --env | -env <env> } 
	--outdir <output dir location> --parallel <parallel degree>  --user <user>
	--allmachines --noemail  ---debug --help --execute

Examples:

	\$  $0 --env ech3  --app auth-server --execute
		: fetch gc log for auth-server only, and put them in the default drop dir: lwang's public folder

	\$  $0 --env ech3  --app all  --outdir ~/mylogs --execute
		: fetch gc logs for all apps in manifest_ech3,   and put them in ~/mylogs

	\$  $0 --env stg  --app all  --outdir ~/mylogs --execute
		: fetch gc logs for all apps in manifest_stg,  and put them in ~/mylogs

	\$  $0 --env stg  --app all --outdir ~/mylogs --user lwang --execute
		: fetch gc logs for all apps in manifest_stg,   and put them in ~/mylogs, using credential of user lwang



NOTES: 
	* Default parallel degree is: $deft_parallel

	* Default <login_name> is whoever runs the script
	
	* By default, we only get the first machine, but --allmachines can be used to get all machines


USAGE


#if ( $help  or @ARGV == 0 ) {
if ( $help or ! ( $app || $file ) ) {
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
my $my_public_folder    = "/Volumes/Staff/Mountain View/Liming Wang/Public/gc_logs";
my $default_drop_dir_root = $my_public_folder;


my $drop_dir_root = $outdir ? $outdir :  $default_drop_dir_root;

die "\nOops.... Please connect to server smb://dfs.foobar.biz and mount the volume \"Staff\" first. \n\n" unless -d "$drop_dir_root"; 


# now that we have the drop dir, mkdir a sub dir
chomp( my $me = `whoami`);
chomp( my $time_stamp = `date +%Y%m%d_%H%M%S`);
print "time_stamp: $time_stamp \n" if $debug;
print "me: $me \n" if $debug;
print "env: $env \n" if $debug;

my $runas = $user ? $user : $me;

my $work_dir = "${time_stamp}_${me}_${env}";

print "work_dir: $work_dir \n" if $debug;


#die "\nOops.... Please connect to server smb://dfs.foobar.biz and mount the volume \"Staff\" first. \n\n" unless -d "$drop_dir_root";
die "\nOops.... I cannot find: $drop_dir_root, or it's not writable by you.  \n\n" unless -w "$drop_dir_root";

umask 0022;
mkdir "$drop_dir_root/$work_dir" if $execute;

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

  my $apps = `$itops_home/bin/cmtool.pl -a get_pools -env $env`;
  
  my @apps = split(" ", $apps);
  
  do_it_in_parallel( @apps );

  
}


send_email() unless $noemail;

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
  
  chomp (my $endtime = `date +%Y%m%d_%H%M%S` );
  
  my $subject = "gc log download is done, please check ...";
  my $msg = "$drop_dir_root/$work_dir/\n\nStarting: $starttime\nEnding: $endtime\n" ;
  my $ccusers = "lwang\@foobar.com,siteops_release\@foobar.com";
  my $tousers = "lwang\@foobar.com rtoppur\@foobar.com";
  
  #| mailx -s "$subject" -c lwang@foobar.com  lwang@foobar.com ];
  
  my $cmd = qq[ echo  "$msg" |  mailx -s "$subject" -c $ccusers $tousers ];
  
  print "Running: $cmd\n" if $debug;
  system( $cmd) if $execute;

}


sub get_all_machines_of  {
  my $app = shift;
  my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $env -pool $app`;
  my @hosts = split(" ", $hosts);

  @hosts;

}


sub get_first_machine {
  my $app = shift;
  my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $env -pool $app`;
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


sub fetch_log {
  my $a = shift;
  my $m = shift;

  my $p = get_path($a);

#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/conf/server_conf.sh  " 2>/dev/null ];
#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/logs/gc.log  " 2>/dev/null ];

  # it's possible that there exist  more than one gc log files 
  chomp(my @logfile_path = `$ssh  $runas\@$m "ls -1 /export/content/$p/i0*/logs/gc.log" 2>/dev/null` );

  if ( @logfile_path > 1 ) {

    # get filtered log file

    foreach my $logfile_path ( @logfile_path ) {
      fetch_filtered_logfile( $logfile_path, $m, $a );
    }

  }
  elsif (  @logfile_path == 1  ) {

    my $logfile_path = shift @logfile_path;

    fetch_filtered_logfile( $logfile_path, $m, $a );

  }
  else {
    print "\n****** No gc.log file found for $a on $m\n\n";
  }

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

sub fetch_filtered_logfile {

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

#  my $logfile = $1 if $logfile_orig =~ m{.*/(.*)};
  my $logfile_filtered = "${a}_${m}_${instance}_${logfile}";

  # push the filter script to remote host
  $cmd = qq[ $scp gen_gc_delta.pl $runas\@$m:~  ];
  do_cmd ( $cmd );

  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; $perl gen_gc_delta.pl  $logfile_orig  $logfile_filtered " ];
  do_cmd ( $cmd );

  # fetch the filtered logfile
  $cmd = qq[ $scp $runas\@$m:~/$logfile_filtered  "$drop_dir_root/$work_dir/$logfile_filtered" ];
  do_cmd ( $cmd );
  

}

sub do_cmd {
  my $cmd = shift;

  print $cmd, "\n" if $debug;
  system( $cmd ) if $execute;

}



