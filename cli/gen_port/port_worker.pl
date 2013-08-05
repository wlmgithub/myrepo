#!/bin/perl -w
#use strict;
#
# lwang: worker to do port gen on ccs box
#

# find . -name server_conf.sh | xargs grep PORT  | awk -F":" '{print $1, "     ", $2}' 

my $env = $ARGV[0];
my $dir_root; 

if ( $env eq 'beta' ) {
  $dir_root = "/export/content/repository/STG-BETA";
}
elsif ( $env eq 'stg' ) {
  $dir_root = "/export/content/repository/STG-ALPHA";
}
elsif ( $env eq 'ech3' ) {
  $dir_root = "/export/content/master_repository/PROD-ECH3";
}
elsif ( $env eq 'ei' ) {
  $dir_root = "/export/content/CCS/repository/QA-EI1";
}
else {
  die "supported env: stg, beta, ech3\n";
}

#my $dir_root = "/export/content/repository/STG-BETA";

chdir( $dir_root ) or die "cannot chdir to $dir_root: $!\n";;

my @server_conf_files = `find . -name server_conf.sh `;

#print @server_conf_files;


my %mapping; # app => [machine] => [instance] => port

for my $scfile ( @server_conf_files ) {
  chomp($scfile);
  next if $scfile =~ /-tomcat/;
#  chomp(my $port = `grep CONTAINER_SERVER_PORT $scfile | cut -f2 -d"="`);

#  print "$scfile : \n";
# ./people-search/esv4-be76/i007/server_conf.sh

#  if ( $scfile =~ m{./(.*)/server_conf.sh}smx  ) {
  if ( $scfile =~ m{./(.*?)/server_conf.sh}smx  ) {
    chomp(my $port = `grep CONTAINER_SERVER_PORT $scfile | cut -f2 -d"="`);
    $mapping{$1} = $port ? $port : '';
  }
#  elsif ( $scfile =~ m{./(.*)/(.*)/server_conf.sh}smx ) {
  elsif ( $scfile =~ m{./(.*?)/(.*?)/server_conf.sh}smx ) {
    chomp(my $port = `grep CONTAINER_SERVER_PORT $scfile | cut -f2 -d"="`);
    $mapping{$1}{$2} = $port ? $port : '';
  }
#  elsif ( $scfile =~ m{./(.*)/(.*)/(.*)/server_conf.sh}smx ) {
  elsif ( $scfile =~ m{./(.*?)/(.*?)/(.*?)/server_conf.sh}smx ) {
    chomp(my $port = `grep CONTAINER_SERVER_PORT $scfile | cut -f2 -d"="`);
    $mapping{$1}{$2}{$3} = $port ? $port : '';
  }

}

#print "\n========\n";

  use Data::Dumper;
#  print Dumper(%mapping);

#print "\++++++++++++++++++++++++\n";


for my $k ( sort keys %mapping ) {
  print "$k : ";
  unless ( exists  $mapping{$k} ) {
    my $ref = $mapping{$k};
    for my $k1 ( sort  keys %$ref ) {
      print "$k1 : ";
      unless ( exists  $mapping{$k}{$k1} ) {
        my $ref2 = $mapping{$k}{$k1};
        for my $k2 ( sort keys %$ref2) {
          print "$k2: ";
          unless ( exists  $mapping{$k}{$k1}{$k2} ) {
            print "$mapping{$k}{$k1}{$k2}\n";
          } else {
            print "NOT POSSILBE!";
          }
        }

      } else {

        print "$mapping{$k}{$k1}\n";
      }  

    } 
  } else {
    print "$mapping{$k}\n";
  }
}

