#!/usr/bin/perl 

#
# lwang: This CGI script is intended to show the manifest
#	
#

use strict;
use CGI qw(:standard);
use Data::Dumper;

#my $server_url = "http://bnd.corp.foobar.com/";
my $server_name = $ENV{SERVER_NAME};
my $script_name = $ENV{SCRIPT_NAME};
my $server_url = "http://$server_name";
my $domain = "foobar.com";

my $env = param("env");
my $env_uc = uc($env);
my $action = param("action");

sub redirect_to {

  my $env = shift;

  my $newurl_root = "http://rotozip.corp.foobar.com/cgi-bin/lwang/rb/genManifest.cgi";
  print "Status: 302 Moved\nLocation: $newurl_root?env=$env\n\n";

}

unless ( $action eq 'legacy' ) {
  for my $e qw( ech3 beta stg ) {
    if ( $env eq $e ) {
      redirect_to( $e );
    }
  }
}

print header();

print start_html("Show Manifest for $env_uc");


unless ( $env_uc eq 'ESV4' or 
	$env_uc eq "PROD" or 
	$env_uc eq "ECH3" or 
	$env_uc eq "STG"  or
	$env_uc eq "BETA" 
	) 
{
#  print "I do not understand environment: $env<br>\n";
#  print "I only understand environments: esv4 or prod or ech3 or stg <br>\n";
  print "I only understand environments:  stg, beta, ech3 <br>\n";
  print end_html();
  exit;
}



#my $config_dir = "/export/content/http/i001/htdocs/cm/configs";
#my $config_dir = "/Library/WebServer/Documents/cm/configs";
#my $config_dir = "/tmp/configs";
#my $config_dir = "/Users/lwang/configs";

#my $manif_file = "manifest_prod";
my $manif_file = "/export/content/http/i001/htdocs/cm/manif/manifest_$env";
my $app_port_file = "/export/content/http/i001/htdocs/cm/manif/app_port";
my $container_mapping_file = "/export/content/http/i001/htdocs/cm/manif/container_mapping_stg";
my $container_mapping_file_beta = "/export/content/http/i001/htdocs/cm/manif/container_mapping_beta";

my $container_port_file = "/export/content/http/i001/htdocs/cm/manif/container_port";
my $container_hosts_file_stg = "/export/content/http/i001/htdocs/cm/manif/container_hosts_stg";
my $container_hosts_file_beta = "/export/content/http/i001/htdocs/cm/manif/container_hosts_beta";


#print  $manif_file, "\n";

#
#============= Machine View
#
if ( $action eq "mview" ) {

  print h1("Machine View for $env_uc");
  print "<a href=\"$server_url/$script_name?env=$env \">  Application View </a>";

  # get machine view
  my %hash;
  
  open my $f, "<", $manif_file or die "cannot open file: $manif_file: $!\n";
  while (<$f>) {
    chomp;
    my ($app, $machines) = ($1, $2) if /(.*)\t(.*)/;
    for ( split(/\s+/, $machines) ) {
      push @{$hash{$_}}, $app;
    }
  }
  close $f;
  
  # present in table

  print "<table border=1>";
  
  print "<tr bgcolor=\"green\"><th> Machine </th>  <th> Apps</th></tr> ";
  
#  while ( my ($machine, $apps) = each %hash) {
#      print "<tr><td> $machine </td>  ";
#      print "<td> @{$apps} </td> </tr>";
#  }

  for my $m ( sort keys %hash ) {
      print "<tr><td> $m </td>  ";
      print "<td> @{$hash{$m}} </td> </tr>";
  }
  
  print "</table>";
    
  print "<br /># of machines: ", scalar keys %hash;

  exit;

}


#
#============= App View, by default
#
print h1("Showing Manifest for $env_uc");
print "<a href=\"$server_url/$script_name?env=$env&action=mview \">   Machine View </a>";

my %app_port_map;
#my %app_machines_map;

open my $fh, "<", "$app_port_file" or die " cannot open file $app_port_file: $!\n";
  my @app_port_lines = <$fh>;
close $fh;

foreach ( @app_port_lines ) {
  if (  /(.*)\t(.*?)\s+/ ) {
    my $app = $1;
    my $port = $2;
    $app_port_map{$app} = $port;
  }
}  

#print Dumper %app_port_map, "\n";

open my $f, "$manif_file" or die "cannot open file $manif_file: $!\n";
  my @lines = <$f>;
close $f;

#foreach (  @lines ) {
#  if (  /(.*)\t(.*)/ ) {
#    my $app = $1;
#    my $machines = $2;
#    $app_machines_map{$app} = $machines;
#  }
#}

#print @lines, "\n";


##### hacking people-search

my %ppsrch_inst_port;
my %ppsrch_mach_insts;

my %liarmemsrch_inst_port;
my %liarmemsrch_mach_insts;

unless ( $env_uc eq 'ECH3' ) {
  handle_container_port_file();
  handle_container_hosts_file();
}


=pod
print "ppsrch_inst_port: <p>";
print Dumper %ppsrch_inst_port;

print "<p>ppsrch_mach_insts: <p>";
print Dumper %ppsrch_mach_insts;

print "<p>";
=cut


my %ppsrch_port = (

'esv4-be17.stg' => 10002,
'esv4-be18.stg' => 10005,
'esv4-be19.stg' => 10002,
'esv4-be20.stg' => 10002,
'esv4-be22.stg' => 10008,
'esv4-be23.stg' => 10160,
'esv4-be35.stg' => 10008,
'esv4-be36.stg' => 10160,

'esv4-be66.stg'  =>  10002,
'esv4-be67.stg'  =>  10003,
'esv4-be68.stg'  =>  10004,
'esv4-be69.stg'  =>  10005,
'esv4-be70.stg'  =>  10006,
'esv4-be71.stg'  =>  10161,
'esv4-be72.stg'  =>  10002,
'esv4-be73.stg'  =>  10003,
'esv4-be74.stg'  =>  10004,
'esv4-be75.stg'  =>  10005,
'esv4-be76.stg'  =>  10006,
'esv4-be77.stg'  =>  10161,

);

my %liar_member_search_port = (


);

print "<table border=1>";

print "<tr bgcolor=\"green\"><th> Application </th> <th> Port </th> <th> Machines</th></tr> ";

foreach  my $line ( @lines ) {
  if ( $line =~ /(.*)\t(.*)/ ) {

    my $app = $1;
    my $machines = $2;

    print "<tr><td> $app </td> <td> $app_port_map{$app} </td> <td> ";
     
    if ( $env eq 'stg' or $env eq 'beta' ) {
      my @machines = split(/\s+/, $machines); 
      for my $m ( @machines ) {
        if ( ! is_front_end_app($app) ) {
          if ( $app eq 'people-search' ) {
            foreach my $h ( keys %ppsrch_mach_insts ) {
              if ( $m eq $h ) {
                print "  $m (";
                for my $inst ( @{$ppsrch_mach_insts{$h}} ) {
                  my $port = $ppsrch_inst_port{$inst};
                  print "  <a href=\"http://$m.$domain:$port/logs\"> logs ($inst)</a> &nbsp;  <a href=\"http://$m.$domain:$port/jmx\"> jmx ($inst)  </a> &nbsp;  ";     
                }
                print ")";
              }
            }
=pod
            if ( $m eq 'esv4-be17.stg' ) {
              print "$m ( <a href=\"http://$m.$domain:10002/logs\"> logs </a> &nbsp;  <a href=\"http://$m.$domain:10002/jmx\"> jmx </a> ) ";     
            } else {
              print "$m ( <a href=\"http://$m.$domain:10005/logs\"> logs </a> &nbsp;  <a href=\"http://$m.$domain:10005/jmx\"> jmx </a> ) ";     
            }
=cut
          } 
          elsif ( $app eq 'liar-member-search' ) {
            foreach my $h ( keys %liarmemsrch_mach_insts ) {
              if ( $m eq $h ) {
                print "  $m (";
                for my $inst ( @{$liarmemsrch_mach_insts{$h}} ) {
                  my $port = $liarmemsrch_inst_port{$inst};
                  print "  <a href=\"http://$m.$domain:$port/logs\"> logs ($inst)</a> &nbsp;  <a href=\"http://$m.$domain:$port/jmx\"> jmx ($inst)  </a> &nbsp;  ";     
                }
                print ")";
              }
            }
          } else {
            print "$m ( <a href=\"http://$m.$domain:$app_port_map{$app}/logs\"> logs </a> &nbsp;  <a href=\"http://$m.$domain:$app_port_map{$app}/jmx\"> jmx </a> ) ";     
          }
        } 
        else {
          print "$m ( <a href=\"http://$m.$domain:12900/$app/logs \"> logs </a> &nbsp;  <a href=\"http://$m.$domain:12001/jmx \"> jmx </a> ) ";     
        }
      }
      print " </td> </tr>";
    }
    else {
      print " $machines </td> </tr>";
    }
  
  }
}

print "</table>";

print "<br /># of components: ", scalar @lines;


print "</pre>";



print end_html();


############## subs
sub is_front_end_app {

  my $app = shift;

  open my $f, "<", $container_mapping_file or die "Cannot open file $container_mapping_file for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^#/;
    return 1 if /^$app\s+/; 
  }
  close $f;

  open my $f, "<", $container_mapping_file_beta or die "Cannot open file $container_mapping_file_beta for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^#/;
    return 1 if /^$app\s+/; 
  }
  close $f;


  return;
}


sub handle_container_port_file {

  # 
  open my $f, "<", $container_port_file or die "cannot open file $container_port_file for reading: $!\n";
  while (<$f>) {
    chomp;
    if ( m{(.*)/(.*)\t(.*)} ) {
      $ppsrch_inst_port{$2} = $3 if $1 eq 'people-search';
      $liarmemsrch_inst_port{$2} = $3 if $1 eq 'liar-member-search';
    }
  }
  close $f;


}


sub handle_container_hosts_file {

  my $file;
  if (  $env eq 'beta' ) {
    $file = "$container_hosts_file_beta" ;
  } 
  elsif (  $env eq 'stg' ) {
    $file = "$container_hosts_file_stg" ;
  }

  open my $f, "<", $file or die "cannot open file $file for reading: $!\n";
  while (<$f>) {
    chomp;
    if (/(.*)\t(.*)/ ) {

      my $col1 = $1;
      my $col2 = $2;

      
      my $inst;
      my $app;
      if ( $col1 =~ /(.*)\/(.*)/ ) {
        $app = $1;
        $inst = $2;
      }
      my @machines = split(/\s+/, $col2);
      if ( $app eq 'people-search' ) {
        for ( @machines ) {
          push @{$ppsrch_mach_insts{$_}}, $inst;
        }
      } 

      if ( $app eq 'liar-member-search' ) {
        for ( @machines ) {
          push @{$liarmemsrch_mach_insts{$_}}, $inst;
        }
      } 
      
    }
  }

  close $f;

}


__END__

people-search   esv4-be17.stg : i001: 10002 | i002: 10003 | i003: 10004 | 
people-search   esv4-be18.stg : i004: 10005 | i005: 10006 | i006: 10007 | 

for my $f ( @config_files ) {

  print li();
  print qq( <a href="$server_url/cgi-bin/cm/showcm_parser.pl?file=$f"> $f  </a><p> );
#  print qq( <a href="$server_url/cm/configs/$f"> $f  </a><p> );

#http://bnd.corp.foobar.com/cgi-bin/cm/showcm_parser.pl?file=extservices.springconfig.dp01.stg

}

