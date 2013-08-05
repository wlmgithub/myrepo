#!/bin/perl
#
# lwang: This script is to take a public_access log file and filter in the time specified
#
# usage:
#	perl filter.pl '2009/10/28 07:05' '2009/10/28 14:30' ws_public_access.log  outfile 
#
# ech3-fe01.prod:lwang[575] /export/content/ws/i001/logs $ perl ~/filter.pl  '2009/11/02 07:05' '2009/11/02 14:18' ws_public_access.log ~/o
#
my $start_stamp = $ARGV[0];  # 2009/10/28 07:00
my $end_stamp = $ARGV[1];    # 2009/10/28 14:59
my $file = $ARGV[2]; # log file to filter
my $outfile = $ARGV[3]; #  out file

#print "start stamp: $start_stamp	$end_stamp\n";

my $this_year = get_year($start_stamp);
my $this_month = get_month($start_stamp);
my $this_day = get_day($start_stamp);

my $start_hour = get_hour($start_stamp);
my $end_hour = get_hour($end_stamp);

my $start_minute = get_minute($start_stamp);
my $end_minute = get_minute($end_stamp);

#print "this year: $this_year\n";
#print "this month: $this_month\n";
#print "this day: $this_day\n";
#print "start hour: $start_hour	$end_hour\n";
#print "start minute: $start_minute	$end_minute\n";

open my $o, ">", $outfile or die "Cannot open for writing: $outfile : $!\n";

open my $f, "<", $file or die "Cannot open file for reading: $!\n";
while (<$f>) {
  chomp;
#  my $line_stamp = $1 if ( m{(\d{4}/\d{2}/\d{2} (\d{2}):(\d{2}.*?))} ) ;

  my $line_year;
  my $line_month;
  my $line_day;

  my $line_hour;

  if  ( m{(\d{4})/(\d{2})/(\d{2}) (\d{2}):(\d{2}):.*?} )  {
    $line_year = $1;
    $line_month = $2;
    $line_day = $3;
    
    $line_hour = $4;
    $line_minute = $5;

    if (   $line_hour >= $start_hour && $line_hour <= $end_hour  and $line_year == $this_year && $line_month == $this_month && $line_day == $this_day  ) {
      print $o  $_, "\n";
    }
  }

#  print "$line_stamp\n";
}
close $f;
close $o;

exit;

sub get_hour {
  my $stamp = shift;

  my $hour = $1 if $stamp =~ /.*? (\d+?):.*/;

  $hour ? $hour : undef;
}

sub get_minute {
  my $stamp = shift;

  my $m = $1 if $stamp =~ /.*? \d{2}:(\d+)/;

  $m ? $m : undef;
}

sub get_year {
  my $stamp = shift;

  my $m = $1 if $stamp =~ m{(\d{4})/.*};

  $m ? $m : undef;
}

sub get_month {
  my $stamp = shift;

  my $m = $1 if $stamp =~ m{\d{4}/(\d{2})/.*};

  $m ? $m : undef;
}

sub get_day {
  my $stamp = shift;

  my $m = $1 if $stamp =~ m{\d{4}/\d{2}/(\d{2}) .*};

  $m ? $m : undef;
}



