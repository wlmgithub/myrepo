#!/bin/perl -w
#
# lwang: find latest ver
#
# $0   /export/content/repository/STG-BETA  cap
# 	-or-
# $0  /export/content/repository/STG-BETA  
#
#
use strict;

my $ccs_root_dir = $ARGV[0];
my $ccs_dirname  = $ARGV[1];


#print "ccs_root_dir: $ccs_root_dir\n";
#print "ccs_dirname: $ccs_dirname \n";

if ( $ccs_dirname ) {
  my $latest = get_latest_ver( $ccs_dirname );
  print "$ccs_dirname : $latest\n";
}
else {

  my @apps = get_all_apps();

  for my $app ( sort @apps ) {
    my $latest = get_latest_ver( $app );
    print "$app : $latest\n";
  }

}


sub get_all_apps {

  chomp ( my @apps = `cd $ccs_root_dir; /bin/ls -d */0.0.* |  cut -d/ -f1 |  sort -u ` );

  return @apps;
  
}

sub get_latest_ver {
  my $ccs = shift;

  chomp ( my @raw_dirs= `cd $ccs_root_dir; /bin/ls -d $ccs/0.0.*` );

  my %ver_of_app;

  my $tmp = 0;
  for my $raw_dir ( @raw_dirs ) {
    if ( $raw_dir =~ m{ (.*)/(.*) }xsm ) {
      my $app = $1;
      my $ver = $2;
      my $stem = $2;  
      $stem =~ s/0.0.//;

      unless (  $ver =~ /0.0.[8-9]\d+/  ) {
        if ( $stem >= $tmp) {
          $ver_of_app{ $app } = $ver;
          $tmp = $stem;
        }
        else {
          $ver_of_app{ $app } = "0.0.$tmp";
        }
      }
    }
  }

  my @values = sort { $a <=> $b  }  values %ver_of_app;
  my $latest = pop @values; 
  return  $latest;

}

