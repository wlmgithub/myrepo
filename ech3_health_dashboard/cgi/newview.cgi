#!/usr/bin/perl -wT
use strict;
use CGI qw(:standard);

use File::stat;
use Time::localtime;


print header();

print start_html(-title=>'ECH3 Health Dashboard',
                 -style => { -src => '/css/main.css',
                             -type => 'text/css',
                             -media => 'screen' },
                 );

print "<p style='font-size:200%; font-weight: bold; '> <img src='/images/NOC.jpg'  width = '250' height = '100' align ='middle' >  ECH3 Health Dashboard  </p>";

### globals
my $year = localtime->year()+1900;
my $month = sprintf("%02d", localtime->mon()+1);
my $day = localtime->mday();
my $ymd = "$year$month$day";  # 20110818

my $DATA_ROOT = "/Library/WebServer/Documents/dashboard/data";
if ( param("date") ) {
  $DATA_ROOT .= '.' . $ymd;
}

my $DATA_FILE = "$DATA_ROOT/services_not_running/data.txt";
my $CAPACITY_AUDIT_DIR = "$DATA_ROOT/capacity_audit";
my $VERSION_MISMATCH_DIR = "$DATA_ROOT/version_mismatch";
my $OWNER_DIR = "$DATA_ROOT/owner";
my $OWNER_FILE = "owner.txt";
my $TOTAL_COUNT_FILE = "$DATA_ROOT/total_count/count.txt";
my $GEN_DATA_STAMP_FILE = "$DATA_ROOT/gen_data_timestamp";

### TODO
my $number_of_services_not_running = get_number_of_services_not_running();
my $number_of_service_hosts_not_running = get_number_of_service_hosts_not_running();
my $number_of_version_mismatch = get_number_of_version_mismatch();
my $number_of_services_in_capacity_audit = get_number_of_services_in_capacity_audit();


### main

my $total_count = get_service_total_count();


if ( param('action')  and  param('action') eq 'show_service_not_running' ) {
  show_service_not_running();
  exit;
}

if (  param('action') and  param('action') eq 'show_capacity_audit' ) {
  show_capacity_audit();
  exit;
}

if (  param('action')  and  param('action') eq 'show_version_mismatch' ) {
  show_version_mismatch();
  exit;
}


print hr();
print p();
print p();
print p();

print "<center>";
show_table();
print "</center>";

print p();
print p();
print p();

show_footer();

sub get_color_of_percent {

  my $percent =  shift;
  my $color;

  if ( $percent >= 30 ) {
    $color = 'red';
  }
  elsif ( $percent < 30 && $percent >= 10 ) {
    $color = 'yellow';
  }
  elsif ( $percent < 10 ) {
    $color = 'green';
  }

  return $color;

}

sub get_gen_data_stamp {

  my $t;
  open my $f, "<", $GEN_DATA_STAMP_FILE or die "cannot open $GEN_DATA_STAMP_FILE: $!\n";
  while(<$f>) {
    chomp;
    $t = $_;
  }
  close $f;

  $t;

}

sub show_table {

#  print "Total Number of Services in ELA4: $total_count\n";
  my $gen_data_stamp = get_gen_data_stamp();
  print "Total Number of Services: $total_count <p>\n";
  print " ( Last Updated: $gen_data_stamp ) \n";

  print "<table>";

  my $percent;
  my $color;
  ###############
  print "<tr>";
  print "<th> Services Not Running </th>";
  print " <td> <a href='?action=show_service_not_running' >    $number_of_services_not_running   </a>  </td>";
  print " <td>   $number_of_services_not_running of  $total_count </td>";

  $percent =  $number_of_services_not_running * 100 / $total_count;
  $color = get_color_of_percent( $percent );
  print " <td bgcolor='$color'>  ", sprintf("%.2f", $percent ), '%', , "</td>";
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> Code Version Mismatch </th>";
  print " <td> <a href='?action=show_version_mismatch' > $number_of_version_mismatch  </a>  </td>";
  print " <td>  $number_of_version_mismatch of  $total_count </td>";

  $percent =  $number_of_version_mismatch * 100 / $total_count;
  $color = get_color_of_percent( $percent );
  print " <td bgcolor='$color'>  ", sprintf("%.2f", $percent ), '%', , "</td>";
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> Application Capacity Audit </th>";
  print "<td> <a href='?action=show_capacity_audit' >  $number_of_services_in_capacity_audit   </a>  </td>";
  print " <td>   $number_of_services_in_capacity_audit of  $total_count </td>";

  $percent =  $number_of_services_in_capacity_audit * 100 / $total_count;
  $color = get_color_of_percent( $percent );
  print " <td bgcolor='$color'>  ", sprintf("%.2f", $percent), '%', , "</td>";
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> ECH3 databus clients</th>";
  print "<td> <a href='http://ech3-ingraphs-vip.prod.foobar.com/dashboard/databus' > Status  </a>  </td>";
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> ECH3 memcache </th>";
  print "<td> <a href='http://ela4-monitor03.prod/dashboard/.memcache_stats_temp' > Status  </a>  </td>";
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> ECH3 DPS snapshot </th>";
  print "<td> <a href='http://ech3-ingraphs-vip.prod.foobar.com/dashboard/dps-snapshot' > Status   </a>  </td>"; 
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> DB replication </th>";
  print "<td> <a href='http://ingraphs.prod.foobar.com/dashboard/database-replication-lag' > Status  </a> </td> ";
  print "</tr>";

  ###############
  print "<tr>";
  print "<th> ECH3 Open Alerts </th>";
  print "<td> <a href='http://ech3-monitor-vip.prod.foobar.com:8080/zport/dmd/Events/viewEvents?notabs=1' > 32  </a>  </td>";
  print "</tr>";

  print "</table>";

}


sub show_service_not_running {

  my $stamp = ctime(stat($DATA_FILE)->mtime);   # e.g. Tue Jul 19 14:14:10 2011

  print "<table>";
  print "<caption> Services Not Running ( services:  $number_of_services_not_running | hosts: $number_of_service_hosts_not_running | Last Updated: $stamp  ) </caption>";

  print "<tr>";
  print "<th> Service </th>";
  print "<th> Owner </th>";
  print "<th> Host </th>";
  print "<th> Status </th>";
  print "</tr>";

  open my $fh, "$DATA_FILE" or die "cannot open file: $DATA_FILE: $!\n";
  while (<$fh>) {
      
    # format: 
    # comm-inbox ech3-cdn21.prod.foobar.com i001 0.0.1126-RC2.6802 stopped
    if ( /(.*?)\s+(.*?)\s+(.*?)\s(.*?)\s+(.*)/  ) {
      my $svc = $1; 
      my $mach = $2; 
      my $inst = $3; 
      my $ver = $4; 
      my $stat = $5; 

      my $owner = get_owner_of($svc);
         
      print "<tr>";
      print "<td> $svc </td>";
      print "<td> $owner </td>";
      print "<td> $mach </td>";
#      print "<td> $inst </td>";
#      print "<td> $ver </td>";
      print "<td> $stat </td>";
      print " </tr>";

    }
  }
  close $fh;

  print "<table>";

}

sub get_number_of_services_not_running {

  my @services;
  open my $fh, "$DATA_FILE" or die "cannot open file: $DATA_FILE: $!\n";
  while (<$fh>) {
    push @services, $1 if /(.*?)\s+.*/;
  }
  close $fh;

  my $ref = array_unique( \@services );

  scalar @{$ref};

}

sub get_number_of_service_hosts_not_running {

  my $n = 0;
  open my $fh, "$DATA_FILE" or die "cannot open file: $DATA_FILE: $!\n";
  while (<$fh>) {
    $n++;
  }
  close $fh;

  $n;

}


sub get_number_of_services_in_capacity_audit {

  my @s;
  opendir my $dh, "$CAPACITY_AUDIT_DIR" or die "cannot open dir: $CAPACITY_AUDIT_DIR: $!\n";
  while ( my $file = readdir $dh ) {
    next if $file =~ /^\./;
    push @s, $1 if $file =~ /(.*)\..*/;
  }
  closedir $dh;

  my $ref = array_unique( \@s );
  
  scalar @{$ref};

}

sub get_number_of_version_mismatch {

  my @s;
  opendir my $dh, "$VERSION_MISMATCH_DIR" or die "cannot open dir: $VERSION_MISMATCH_DIR: $!\n";
  while ( my $file = readdir $dh ) {
    next if $file =~ /^\./;
    push @s, $1 if $file =~ /(.*)\..*/;
  }
  closedir $dh;

  my $ref = array_unique( \@s );
  
  scalar @{$ref};

}



sub get_capacity_audit_files  {

  my @files;

  opendir my $dh, $CAPACITY_AUDIT_DIR or die "cannot open dir $CAPACITY_AUDIT_DIR: $!\n";
  while ( my $file = readdir $dh ) {
    next if $file =~ /^\./;
    push @files, $file;
  }
  closedir $dh;

  @files;

}

sub get_version_mismatch_files  {

  my @files;

  opendir my $dh, $VERSION_MISMATCH_DIR or die "cannot open dir $VERSION_MISMATCH_DIR: $!\n";
  while ( my $file = readdir $dh ) {
    next if $file =~ /^\./;
    push @files, $file;
  }
  closedir $dh;

  @files;

}




sub show_capacity_audit {

  my @files = get_capacity_audit_files();

  my %h;   # h: svc -> fabric -> content 
  my %ht;  # ht: svc -> fabric -> timestamp
#  print "@files\n";
  
  for my $file ( @files ) {
    # abook.ela4
    if ( $file =~ /(.*)\.(.*)/ ) {
      my $svc = $1;
      my $fab = $2;
      my @content;

      my $stamp = ctime(stat("$CAPACITY_AUDIT_DIR/$file")->mtime);
      
      # rlamba-2-md /Library/WebServer/Documents/dashboard/data/capacity_audit $ cat oms.ela4 
      #  ela4-be41.prod.foobar.com
      #  ela4-be42.prod.foobar.com
      #  ela4-be43.prod.foobar.com
      #  ela4-be532.prod.foobar.com
      open my $f, "$CAPACITY_AUDIT_DIR/$file" or die "cannot open file $CAPACITY_AUDIT_DIR/$file for reading: $!\n";
      @content = <$f>;
      close $f;
      $h{$svc}{$fab} = @content;
      $ht{$svc}{$fab} = $stamp;

    }
  }

  print "<table>";
  print "<caption> Capacity Audit </caption>";
  print "<tr>";
  print "<th> Service  </th>";
  print "<th> Owner </th>";
  print "<th> ECH3 </th>";
  print "<th> Hosts Count</th>";
  print "<th> Last Updated </th>";
  print "<th> ELA4 </th>";
  print "<th> Hosts Count </th>";
  print "<th> Last Updated </th>";
  print "</tr>";
  for  my $s ( sort (keys %h) ) {
    print "<tr> <td> $s </td> ";
    my $owner = get_owner_of($s);
    print " <td>  $owner </td>";
    for my $f ( sort (keys  %{$h{$s}} ) ) {

      print " <td>  $f </td>";
      print " <td>  $h{$s}{$f} </td> ";
      print " <td>  $ht{$s}{$f} </td> ";

    }
    print "</tr>";
  }
  print "</table>";

}


sub show_version_mismatch {

  my @files = get_version_mismatch_files();

  my %h;  # h: svc -> fabric -> content 
  my %hc;  # hc: svc -> fabric -> content count
  my %ht;  # ht: svc -> fabric -> timestamp
  
  for my $file ( @files ) {
    # abook.ela4
    if ( $file =~ /(.*)\.(.*)/ ) {
      my $svc = $1;
      my $fab = $2;
      my @content;

      my $stamp = ctime(stat("$VERSION_MISMATCH_DIR/$file")->mtime);

      #
      # rlamba-2-md /Library/WebServer/Documents/dashboard/data/version_mismatch $ cat oms.ela4 
      #  oms ela4-be41.prod.foobar.com i001 0.0.1126-RC2.7011 running
      #  oms ela4-be42.prod.foobar.com i001 0.0.1126-RC2.7011 running
      #  oms ela4-be43.prod.foobar.com i001 0.0.1126-RC2.7011 running
      #  oms ela4-be532.prod.foobar.com i001 0.0.1126-RC2.7011 running
      #
      open my $f, "$VERSION_MISMATCH_DIR/$file" or die "cannot open file $VERSION_MISMATCH_DIR/$file for reading: $!\n";
      @content = <$f>;
      close $f;
      @{$h{$svc}{$fab}} = @content;
      $hc{$svc}{$fab} = @content;
      $ht{$svc}{$fab} = $stamp;

    }
  }

  print "<table>";
  print "<caption>  Version Mismatch </caption>";
  print "<tr>";
  print "<th> Service </th>";
  print "<th> Owner </th>";
  print "<th> ECH3 </th>";
  print "<th> Count </th>";
  print "<th> Details </th>";
  print "<th> Last Updated </th>";
  print "<th> ELA4 </th>";
  print "<th> Count </th>";
  print "<th> Details </th>";
  print "<th> Last Updated </th>";
  print "</tr>";

  for  my $s ( sort (keys %h) ) {
    print "<tr>";
    print " <td> $s </td> ";
    my $owner = get_owner_of($s);

    print "<td> $owner  </td>";
    for my $f ( sort (keys  %{$h{$s}} ) ) {
      print " <td>  $f </td> ";
      print " <td> $hc{$s}{$f}  </td> ";
      print "<td>";  
#      print join("&lt;p&gt;", @{$h{$s}{$f}});
      for my $line ( @{$h{$s}{$f}} ) {
        print "$line <br>";
      }
      print " </td>";
      print " <td> $ht{$s}{$f}  </td> ";

    }
    print " </tr> ";
  }
  print "</table>";

}



###############
sub array_unique {

  my $ref_in = shift;
  my @in = @$ref_in;

  my %saw;

  undef %saw;
  my @out = grep(!$saw{$_}++, @in);

  return \@out;

}


sub show_footer {

  print "<hr />";
#  print img( { -src => '/lwang/images/bottombar.png',  -align => 'center'  } );
#  print img( { -src => '/lwang/images/bottombar.png', -style => 'position:center,overflow; width: 1500; height: 20      '  } );
  print "<center>";
  print "<a href='https://iwww.corp.foobar.com/wiki/cf/display/NOC/ECH3+Health+Dashboard' target='_blank'>  ECH3 Health Wiki </a>  ";
  print " | ";
  print "Email: <a href='mailto:noc\@foobar.com'> noc\@foobar.com </a> ";
  print "</center>";

}

use Memoize;
memoize('get_owner_of');

sub get_owner_of {

  my $svc = shift;
  
  my $owner;
  open my $fh, "$OWNER_DIR/$OWNER_FILE" or die "cannot open file $OWNER_DIR/$OWNER_FILE: $!\n";
  while(<$fh>) {
    next if /^#/;
    chomp;
    $owner = $1 if /^\b$svc\E\s+(.*)/;
  }
  close $fh;

  return $owner; 

}



sub get_service_total_count {

  # rlamba-2-md /Library/WebServer/Documents/dashboard/data/total_count $ cat count.txt 
  #   320
  open my $fh, $TOTAL_COUNT_FILE or die "cannot open $TOTAL_COUNT_FILE: $!\n";
  chomp(my $count = <$fh>);
  close $fh;

  return $count; 

}

