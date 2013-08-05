#!/bin/perl
#
# lwang: This script is to take a gc.log and generate a delta, if any
#
# usage:
#	perl $0 orig_gc_log delta_gc_log
#
# ech3-leo30.prod:lwang[268] ~ $ ./gen_gc_delta.pl /export/content/leo-tomcat/i001/logs/gc.log gc.log

my $debug = 0;

use File::Copy;
use File::Basename;

#
my $file = $ARGV[0];  # orig gc log file
my $outfile = $ARGV[1]; #  delta gc log file

my $name = basename($file);
my $file_prev = "${name}.prev";

# do this if file_prev not exists
unless ( -e "$file_prev" ) {
  copy($file, "orig") if $debug;
  copy($file, $file_prev);
  copy($file, $outfile);
  exit;
}

my $head_of_prev = `head $file_prev`;
my $head_of_new = `head $file`;

#
# if file_prev exists, see if the new gc.log is in the same running proc as the prev one
# if yes, 
#	- generate delta
#	- create a new file_prev as the next check point
# if no,
#	- use the new file as file_prev 
#	- use the new file as delta
#
if ( $head_of_new eq $head_of_prev ) {

  if ( $debug ) {
    print "\nhead same\n";
    print "\nfile: $file\n";
    print "\nfile_prev: $file_prev\n";
    print "\noutfile: $outfile\n";
  }
  
  copy($file, "orig") if $debug;

#  system("wc -l $file");
  
  chomp( my $wcl_prev = `wc -l $file_prev | awk '{print $1}'`);
  
  print "\nwcl_prev: $wcl_prev\n" if $debug;
  
  my $delta_starting_line_number = $wcl_prev + 1;
  
  print "\ndelta_starting_line_number: $delta_starting_line_number\n" if $debug;
  
  my $cmd = qq[perl -ne 'print if $delta_starting_line_number..0' $file > $outfile ];
  
  print "\ncmd: $cmd\n" if $debug;
  
  system( $cmd );

  copy($file, $file_prev);

}
else {

  print "\nhead NOT same\n" if $debug;
  copy($file, $file_prev);
  copy($file, $outfile);

}

exit;
