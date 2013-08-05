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

use Getopt::Long;

use POSIX 'WNOHANG';
$SIG{CHLD} = sub { while( waitpid(-1, WNOHANG)  > 0 ) { } };

my $help;
my $debug;
my $app;
my $execute;
my $checkpoint;
my $start;	# start time stamp
my $end;	# end time stamp
my $parallel;	# parallel degree
my $file;	# file containing apps interested
my $perl = "/bin/perl";
my $gtar = "/usr/sfw/bin/gtar";
my $ssh = "/bin/ssh";
my $scp = "/bin/scp";
my $env;
my $outdir;	# where you want to put the logs
my $user;	# do ssh as user, otherwise as whoever runs the scr 

my $deft_parallel = 1;  	# default parallel degree
my $gc = "gc.log";
my $applog;

GetOptions(
	"user=s" => \$user,
	"outdir=s" => \$outdir,
	"file=s" => \$file,
	"parallel=s" => \$parallel,
	"start=s" => \$start,
	"end=s" => \$end,
	"env=s" => \$env,
	"app=s" => \$app,
	"help" => \$help,
	"debug" => \$debug,
	"execute" => \$execute,
	"checkpoint" => \$checkpoint,
);

my $usage =<<USAGE;

Usage:

  $0 	{ [ --app | -a  <appname> ] | [ --file | -f <file> ]  } { --env | -env <env> } 
	{ --start <start time stamp> } {  --end <end time stamp> }  
	--outdir <output dir location> --parallel <parallel degree>  --user <user>
	---debug --help --execute

Examples:

	\$  $0 --env ech3  --app auth-server --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --execute
		: fetch public_access log for auth-server only, in the time window specified, and put them in the default drop dir: Hari's public folder

	\$  $0 --env ech3  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --outdir ~/mylogs --execute
		: fetch public_access logs for all apps in manifest_ech3,  in the time window specified, and put them in ~/mylogs

	\$  $0 --env stg  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --outdir ~/mylogs --execute
		: fetch public_access logs for all apps in manifest_stg,  in the time window specified, and put them in ~/mylogs

	\$  $0 --env stg  --app all  --start '2009/11/02 07:05'  --end '2009/11/02 14:18' --outdir ~/mylogs --user lwang --execute
		: fetch public_access logs for all apps in manifest_stg,  in the time window specified, and put them in ~/mylogs, using credential of user lwang



NOTES: 	* The minute part in the timestamp is ignored for now. e.g., -start '2009/11/02 07:05' -end '2009/11/02 14:18' is the same as -start '2009/11/02 07:00' -end '2009/11/02 14:00' 
          which means fetching lines with time from '2009/11/02 07:00' to '2009/11/02 14:59'

	* Default parallel degree is: $deft_parallel

	* Default <login_name> is whoever runs the script


USAGE


#if ( $help  or @ARGV == 0 ) {
if ( $help or ! ( $app || $file ) ) {
  print $usage;
  exit;
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
my $drop_dir_root = $outdir ? $outdir : "/Volumes/Staff/Mountain View/Haricharan Ramachandra/Public/log_fetching";

print " This is the output dir - ${drop_dir_root} \n";  
#die "\nOops.... Please connect to server smb://dfs.foobar.biz and mount the volume \"Staff\" first. \n\n" unless -d "$drop_dir_root";
#die "\nOops.... I cannot find: $drop_dir_root, or it's not writable by you.  \n\n" unless -w "$drop_dir_root";


# need ITOPS_HOME env var to run 
die "Please have your ITOPS_HOME environment variable set.\n" unless $ENV{ITOPS_HOME};
chomp(my $itops_home =  $ENV{ITOPS_HOME});




# now that we have the drop dir, mkdir a sub dir
chomp( my $me = `whoami`);
chomp( my $time_stamp = `date +%Y%m%d_%H%M%S`);
print "time_stamp: $time_stamp \n" if $debug;
print "me: $me \n" if $debug;
print "env: $env \n" if $debug;

my $runas = $user ? $user : $me;

my $work_dir = "${time_stamp}_${me}_${env}";

print "work_dir: $work_dir \n" if $debug;

umask 0022;
mkdir "$drop_dir_root/$work_dir" if $execute;

# now get to work...

if ( $app &&  $app ne 'all'  ) {

  if($env eq 'stg')
  {
    my @mhosts = get_all_machines($app);
    my $mm;
    $applog = "${app}.log";
    foreach $mm ( @mhosts )
    {
        if($checkpoint)
	{
	     fetch_cp($app,$mm,$gc,"gctrue");
	     fetch_cp($app,$mm,$applog,"gcfalse");
	}
	else
	{
	 fetch_log( $app, $mm);
         fetch_gc( $app, $mm,$gc,"gctrue");
         fetch_gc( $app, $mm,$applog,"gctrue");
  	}
    }
  }
  else 
  {
	     my $m = get_first_machine( $app );
         	print STDERR "\nINFO: fetching log for $app on $m\n" if $debug ;
     		fetch_log( $app, $m);
     		fetch_gc( $app, $m,$gc);
  }
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

#  foreach my $app ( @apps ) {
#
#    next if $app =~ /^memcache/;
#
#    my $m = get_first_machine( $app );
#
#    print "\nINFO: fetching log for $app on $m\n" if $debug ;
#
#    fetch_log( $app, $m);
#
#  }


}
else {

  my $apps = `$itops_home/bin/cmtool.pl -a get_pools -env $env`;

print "\n===1111===$apps====\n";
  
  my @apps = split(" ", $apps);
  
  do_it_in_parallel( @apps );

#  foreach my $app ( @apps ) {
#
#    next if $app =~ /^memcache/;
#  
#    my $m = get_first_machine( $app );
#  
#    print "\nINFO: fetching log for $app on $m\n" if $debug ;
#
#    fetch_log( $app, $m);
#  
#  }
  
}


send_email();

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
  
#      print "BEFORE FOR BRACKET\n";
  }
  
#      print "AFTER FOR BRACKET\n";
  
#  system(" ps -efwa | grep perl ");
  
      foreach (@childs) {
        waitpid($_, 0);
      }
  
#  print "\n==============\n";
#  system(" ps -efwa | grep perl ");
  
}

sub doit {

  my $app = shift;

  return if $app =~ /^memcache/;
  #print "\nINFO: fetching log for $app on $m\n" if $debug ;
  if($env eq 'stg')
  {
    my @mhosts = get_all_machines($app);
    my $mm;
    $applog = "${app}.log";
    foreach $mm ( @mhosts )
    {
	 if($checkpoint)
        {
             fetch_cp($app,$mm,$gc,"gctrue");
             fetch_cp($app,$mm,$applog,"gcfalse");
        }
        else
        {
       		fetch_log( $app, $mm);
        	fetch_gc( $app, $mm,$gc,"gctrue");
        	fetch_gc( $app, $mm,$applog,"gcfalse");
        }
    }
  }
  else
  {
     my $m = get_first_machine( $app );
     print STDERR "\nINFO: fetching log for $app on $m\n" if $debug ;
     fetch_log( $app, $m);
     fetch_gc( $app, $m,$gc);
  }


}





sub send_email {

  # send email when done
  # hramachandra@foobar.com
  # echo "/Volumes/Staff/Mountain View/Haricharan Ramachandra/Public/log_fetching/20091028_lwang/" | mailx -s "log download is done, please check ..." lwang@foobar.com
  
  chomp (my $endtime = `date +%Y%m%d_%H%M%S` );
  
  my $subject = "log download is done, please check ...";
  my $msg = "$drop_dir_root/$work_dir/\n\nStarting: $starttime\nEnding: $endtime\n" ;
  my $ccusers = "lwang\@foobar.com,siteops_release\@foobar.com";
  my $tousers = "hramachandra\@foobar.com es-performance\@foobar.com";
  
  #| mailx -s "$subject" -c lwang@foobar.com  lwang@foobar.com ];
  
  my $cmd = qq[ echo  "$msg" |  mailx -s "$subject" -c $ccusers $tousers ];
  
  print "Running: $cmd\n" if $debug;
  system( $cmd) if $execute;

}


sub get_first_machine {
  my $app = shift;
  my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $env -pool $app`;
print "\n===2222=======33333$app======$hosts====\n";
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

sub get_all_machines {
  my $app = shift;
  my $hosts = `$itops_home/bin/cmtool.pl -a get_pool_hosts -env $env -pool $app`;
print "\n===4444=======33333$app======$hosts====\n";
  my @hosts = split(" ", $hosts);

  #
  # ugly special cases... yucky
  #
  if ( $app eq 'nus' && $env eq "ech3"  ) {
    'ech3-cdn31.prod';
  }
  else {
   @hosts;
  }
}


sub fetch_log {
  my $a = shift;
  my $m = shift;

  my $p = get_path($a);

#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/conf/server_conf.sh  " 2>/dev/null ];
#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/logs/*public_access.log  " 2>/dev/null ];

  # it's possible that there exist  more than one public_access files 
  chomp(my @logfile_path = `$ssh  $runas\@$m "ls -1 /export/content/$p/i001/logs/*public_access.log" 2>/dev/null` );

  if ( @logfile_path > 1 ) {

    # get filtered log file

    foreach my $logfile_path ( @logfile_path ) {
      fetch_filtered_logfile( $logfile_path, $m );
    }

  }
  elsif (  @logfile_path == 1  ) {

    my $logfile_path = shift @logfile_path;

    fetch_filtered_logfile( $logfile_path, $m );

  }
  else {
    print "\n****** No public_access file found for $a on $m\n\n";
  }

}


sub fetch_gc {
  my $a = shift;
  my $m = shift;
  my $l = shift;
  my $gctrue = shift;
  print " in fetch_gc fetching ... ${l} \n";
  my $p = get_path($a);

#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/conf/server_conf.sh  " 2>/dev/null ];
#  my $cmd = qq[ ssh $m " ls -l /export/content/$p/i001/logs/*public_access.log  " 2>/dev/null ];

  # it's possible that there exist  more than one public_access files
  chomp(my @logfile_path = `$ssh  $runas\@$m "ls -1 /export/content/$p/i001/logs/$l" 2>/dev/null` );

  if ( @logfile_path > 1 ) {

    # get  log file

    foreach my $logfile_path ( @logfile_path ) {
      fetch_full_logfile( $logfile_path, $m);
    }

  }
  elsif (  @logfile_path == 1  ) {

    my $logfile_path = shift @logfile_path;

    fetch_full_logfile( $logfile_path, $m );

  }
  else {
    print "\n****** No public_access file found for $a on $m\n\n";
  }

}

sub fetch_cp {
  my $a = shift;
  my $m = shift;
  my $l = shift;
  my $gctrue = shift;
  my $p = get_path($a);

  print " ########### in fetch_cp fetching ... ${l} \n";
  # it's possible that there exist  more than one public_access files
  chomp(my @logfile_path = `$ssh  $runas\@$m "ls -1 /export/content/$p/i001/logs/$l" 2>/dev/null` );

  if ( @logfile_path > 1 ) {

    # get  log file

    foreach my $logfile_path ( @logfile_path ) {
      print " calling checkpoint ... ${logfile_path} on machine ${m}";
      get_checkpoint( $logfile_path, $m);
    }

  }
  elsif (  @logfile_path == 1  ) {

    my $logfile_path = shift @logfile_path;
    print " calling checkpoint ... ${logfile_path} on machine ${m}";
    get_checkpoint( $logfile_path, $m );

  }
  else {
    print "\n****** No file found for $a on $m\n\n";
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
  my $cmd;
  my @timeData = localtime(time);
  my $time = join('_', @timeData); 
  my @dat = split(/\//,$logfile_orig);


  my $logfile = $1 if $logfile_orig =~ m{.*/(.*)};
  my $logfile_filtered = "${m}_${dat[4]}_$logfile";
  my $logfile_filtered_tgz = "${m}_${logfile}.tgz";
  print " FILTERING \n ...";
  print " logfile_orig = ${logfile} \n";
  print " logfile_filtered = ${logfile_filtered} \n";
  print " logfile_filtered_tgz = ${logfile_filtered_tgz} \n";

  # push the filter script to remote host
  $cmd = qq[ $scp filter.pl $runas\@$m:~  ];
  do_cmd ( $cmd );

  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; $perl filter.pl '$start' '$end'  $logfile_orig  $logfile_filtered " ];
  print $cmd;
  do_cmd ( $cmd );


  $cmd = qq[ $ssh -l $runas $m "cd ~; du -kh $logfile_orig " ];
  do_cmd ( $cmd );
  
  $cmd = qq[ $ssh -l $runas $m "cd ~; du -kh  $logfile_filtered " ];
  do_cmd ( $cmd );


  # gtar
  #$cmd = qq[ $ssh -l $runas $m "cd ~; $gtar czf $logfile_filtered_tgz  $logfile_filtered"  ];
  #do_cmd ( $cmd );

  # fetch the filtered logfile
  $cmd = qq[ $scp $runas\@$m:~/$logfile_filtered  "$drop_dir_root/$work_dir/${logfile_filtered}" ];
  do_cmd ( $cmd );


}

sub get_checkpoint {

  my $logfile_orig = shift;
  my $m = shift;
  my $cmd;
  my @timeData = localtime(time);
  my $time = join('_', @timeData);

  my $logfile = $1 if $logfile_orig =~ m{.*/(.*)};
  my $logfile_filtered = "${m}_${app}_$logfile";
  my $logfile_key = "${m}_${app}_${logfile_orig}";
  my $tmpout = "tmp.hari";
  print " THIS IS TESTING \n";
  print " app = ${app}  \n";

  print " logfile = ${logfile} ";
  print " logfileOrig = ${logfile_orig} ";

 
  # get line count 
  #$cmd = qq[ $ssh -l $runas $m "cd ~;wc -l $logfile_orig > ~/$tmpout" ];
  `ssh $runas\@$m wc -l $logfile_orig > $tmpout`;
  #do_cmd ( $cmd );
  # fetch the filtered logfile
  #$cmd = qq[ $scp $runas\@$m:$tmpout "/export/home/tester/logfetch/itops/trunk/proj/log_fetching/$tmpout" ];
  #do_cmd ( $cmd );
  print " printing the scpd file ........ \n";
  #$cmd = qq[ cat "$drop_dir_root/$work_dir/$tmpout"];
  $cmd = "cat /export/home/tester/logfetch/itops/trunk/proj/log_fetching/tmp.hari | awk '{print \"${logfile_key}:\"\$1}' >> check.point";
  do_cmd ( $cmd );
 
  print " END OF TESTING \n";


}


sub fetch_full_logfile {

  my $logfile_orig = shift;
  my $m = shift;
  my $cmd;
  my @timeData = localtime(time);
  my $time = join('_', @timeData);
  my @dat = split(/\//,$logfile_orig);

 my $logfile = $1 if $logfile_orig =~ m{.*/(.*)};
 my $logfile_filtered = "${m}_${dat[4]}_${dat[3]}_$logfile";
 my $logfile_tgz = "${m}_${app}_${logfile}.tgz";
 my $logfile_key = "${m}_${app}_${logfile_orig}";
  #print " downloading log file - ${logfile_filtered}  FOR THE KEY = ${logfile_key} ---------------------------------------------------\n";
  # push the filter script to remote host
  #$cmd = qq[ $scp filter.pl $runas\@$m:~  ];
  #do_cmd ( $cmd );

  if( -e "check.point" )
  {
    my $val = `fgrep "$logfile_key" check.point`; 
    my @vary = split(/:/,$val);
    my $line = $vary[1];
    #print "  ########################################## line value = ${line} \n";
    my $line_num = int($line);
    
    if( $line_num gt 0 ) 
    {
     my $p;
     # create logfile_filtered
     #$cmd = qq[ $ssh -l $runas $m "cd ~; cat $logfile_orig | awk 'NR > $line_num' > $logfile_filtered" ];
     $cmd = qq[ $ssh -l $runas $m "cd ~; perl -ne 'print if $line..0' $logfile_orig > $logfile_filtered" ];
     print "##### EXECUTING THE COMMAND ${cmd}"; 
     do_cmd ( $cmd );
	

    }
    else
    {



    }
  }
  else
  {

  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; cp $logfile_orig  $logfile_filtered " ];
  do_cmd ( $cmd );


  }


  print " THIS IS TESTING ";
  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; du -kh  $logfile_orig " ];
  do_cmd ( $cmd );

  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; du -kh $logfile_filtered " ];
  do_cmd ( $cmd );
 
  # create logfile_filtered
  $cmd = qq[ $ssh -l $runas $m "cd ~; wc -l $logfile_orig " ];
  do_cmd ( $cmd );

  print " END OF TESTING ";

  # gtar
  #$cmd = qq[ $ssh -l $runas $m "cd ~; $gtar czf $logfile_tgz  $logfile"  ];
  #do_cmd ( $cmd );

  # fetch the filtered logfile
  $cmd = qq[ $scp $runas\@$m:~/$logfile_filtered  "$drop_dir_root/$work_dir/$logfile_filtered" ];
  do_cmd ( $cmd );


}


sub do_cmd {
  my $cmd = shift;

  print $cmd, "\n" if $debug;
  system( $cmd ) if $execute;
  system( $cmd ) if $checkpoint;

}


