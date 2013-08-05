#!/bin/perl -w
#!/bin/perl -wT
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

# 
# globals
#
my $pid = $$;
my $debug = 0;
my $wget = "/usr/sfw/bin/wget";
my $hcurl = "http://ech3-cfg01.prod.foobar.com:10094/healthcheck-console/config.jsp";
my %mapping;  # key => comp => ver  => value 
my %latest_ver_of; # comp => latest_ver
my %vers_of; #  comp => vers
my %key_ver_val_to_comps;  # k => v => val => comps

my @comps = qw(
        leo
        nhome
        reg
        pprofile
        profile
        lmt
        targeting-svcs
);


$ENV{PATH} .= ':/usr/sfw/bin';

#my $version=param("version");
$debug = param("debug");

print header;

print "Fetching data...... may take about 30 seconds......<p>";

print <<EOM;
NOTES:
<ul>
<li>  The A/B test key/value pairs are taken from the <b>abTestStringConfigMap</b> block only
<li>  The components inspected are:   <b>  @comps  </b>
</ul>
EOM

#<li>  The components inspected are:   <b>leo, nhome, reg, pprofile, profile, lmt  </b>

my $tstamp = `date`;
print "$tstamp<p>" if $debug;

print "@comps\n" if $debug;

#### get config.jsp file
get_config_jsp_file();

my $tstamp = `date`;
print "<p>After running get_config_jsp_file: $tstamp<p>" if $debug;


#### parse config.jsp file
parse_config_jsp_file();
remove_config_jsp_file();

my $tstamp = `date`;
print "<p>After running parse_config_jsp_file: $tstamp<p>" if $debug;


#print Dumper(%latest_ver_of);

my $tstamp = `date`;
print "<p>After dumping %latest_ver_of: $tstamp<p>" if $debug;


#print Dumper(%vers_of);

for my $c ( @comps ) {
  get_config_file_of($c);
}


my $tstamp = `date`;
print "<p>After running get_config_file_of each comp : $tstamp<p>" if $debug;

#print $version, "<p>";


#### now that we have the config files, parse them, and get a/b test key/val pairs
parse_config_files();

for my $c ( @comps ) {
  remove_config_file_of($c);
}

$tstamp = `date`;
print "<p>After running parse_config_files: $tstamp<p>" if $debug;

#print "<p> Number of rows: " , scalar keys %key_ver_val_to_comps, "<p>";
print "Done<p>" if $debug;

print end_html;
exit(0);

#
# subs
#

sub get_config_jsp_file {
  system("$wget $hcurl -O data/config.jsp.$pid");
}

sub remove_config_jsp_file {
  system("rm data/config.jsp.$pid");
}

sub parse_config_jsp_file {


#<p>                    <a href="config.jsp?config=/PROD-ECH3/pprofile/0.0.506/extservices.springconfig">/PROD-ECH3/pprofile/0.0.506/extservices.springconfig</a>
#<p>                    <a href="config.jsp?config=/PROD-ECH3/pprofile/0.0.998/ech3-fe07/extservices.springconfig">/PROD-ECH3/pprofile/0.0.998/ech3-fe07/extservices.springconfig</a>

  open my $f, "<", "data/config.jsp.$pid" or die "cannot open config.jsp.$pid file: $!\n";
  while (<$f>) {
    for my $c ( @comps ) {
      if ( m{.*/PROD-ECH3/$c/(0.0.\d+)/.*} ) {
#        print "$_<p>";
        push @{$vers_of{$c}}, $1;
      }
    }
  }
  close $f;

  # get the uniq array
  for my $c ( @comps ) {
    my $ref = array_unique($vers_of{$c});
    my $temp = $ref;
    $vers_of{$c} = $temp;

    my @versions = sort @$ref;
    for ( reverse @versions ) {
      my $stem = $_; $stem =~ s/0\.0\.//g;
      if ( $stem >= 1040 ) { ######### TODO ########
        $latest_ver_of{$c} = $_;
        last;
      } 
    }
  }


}


sub get_configs {

  system("$wget $hcurl?config=/PROD-ECH3/lmt/0.0.505/extservices.springconfig -O data/lmt ");

}

sub remove_config_file_of {

  my $comp = shift;

  system("rm  data/$comp.$pid");

}

sub get_config_file_of {

  my $comp = shift;

  system("$wget $hcurl?config=/PROD-ECH3/$comp/$latest_ver_of{$comp}/extservices.springconfig -O data/$comp.$pid");

}

sub array_unique {

  my $ref_in = shift;
  my @in = @$ref_in;

  my %saw;

  undef %saw;
  my @out = grep(!$saw{$_}++, @in);

  return \@out;

}

sub parse_config_files {

  


  for my $comp ( @comps ) {
    print "$comp...\t\n\t" if $debug;
    my $latest_version = $latest_ver_of{$comp};
    print "latest_version: $latest_version\n" if $debug;
  
     gen_mapping($comp, $latest_version);
  
  }

#print "<pre>";  
#print Dumper(%mapping);
#print "</pre>";  
 

#print "<p>==================<p>";


for my $k ( keys %mapping ) {
LOOP:
  for my $c ( keys %{$mapping{$k}} ) {
    for my $v ( keys %{$mapping{$k}{$c}}  ) {
      my $val = $mapping{$k}{$c}{$v};

      if ( exists $key_ver_val_to_comps{$k} ) {
        for my $k_new ( keys %key_ver_val_to_comps ) {
          for my $v_new ( keys %{$key_ver_val_to_comps{$k_new}} ) {
            for my $val_new ( keys %{$key_ver_val_to_comps{$k_new}{$v_new}} ) {

              if ( $k_new eq $k && $v_new eq $v && $val_new eq $val ) {
                $key_ver_val_to_comps{$k_new}{$v_new}{$val_new} .= ",$c";
              }
              else {
                $key_ver_val_to_comps{$k}{$v}{$val} .= ",$c";
              }
next LOOP;
            }
          }
        }
      }
      else {
        $key_ver_val_to_comps{$k}{$v}{$val} = $c;
      }
    }
  }
}


=pod
print "<pre>";  
print Dumper(%key_ver_val_to_comps);
print "</pre>";  
=cut


print "<table border='2'>";

print "<tr bgcolor='green'><th> Key </th><th> Component(s)  </th><th> Version </th><th> Value</th></tr>";

=pod
#print "\n444444444444444\n";
  for my $k ( keys %mapping ) {

    for my $c ( keys %{$mapping{$k}} ) {

      for my $v ( keys %{$mapping{$k}{$c}}  ) {
        my $val =  $mapping{$k}{$c}{$v};
#        $val =~ s/{/\\{/g ;
#        $val =~ s/}/\\}/g ;

        print "<tr><td> $k </td><td> $c </td><td> $v </td><td>  $val </td></tr>";

      }
#      print "\\\\\n";

    }

  }
=cut

  for my $k ( sort keys %key_ver_val_to_comps ) {
    for my $v ( keys %{$key_ver_val_to_comps{$k}} ) {
      for my $val ( keys %{$key_ver_val_to_comps{$k}{$v}}  ) {
        my $comps =  $key_ver_val_to_comps{$k}{$v}{$val};
        $comps =~ s/^,//; 
        print "<tr><td> $k </td><td> $comps </td><td> $v </td><td>  $val </td></tr>";
      }
    }
  }
print "</table>";



}

sub gen_mapping {

  my $comp = shift;

  my $latest_version = shift;

  my $file = "data/$comp.$pid";

  open my $f, "<", $file or die "cannot open file $file for reading: $!\n";
  my @array = <$f>;
  close $f;

  my @blocks;
  for my $i ( 0..$#array ) {

    if ( $array[$i] =~ /abTestStringConfigMap/ ) {
  
      my $j = 1;
      while (  $array[$i+$j] !~  m{&lt;/map&gt} ) {  # </map>
        push @blocks, $array[$i+$j] ;
        $j++;
      }
    }
  }

#print "\n33333333333333333333333333333 $comp, $latest_version  \n";
#print Dumper(@blocks);

  for my $line ( @blocks ) {
    
    if ( $line =~ m{entry key="} && $line !~ m{&lt;!--} ) {   # <!-->

      my ($key, $val) = get_keyval($line) ;
  
  # &lt;entry key="com.pronet.leo.bl.abook.impl.MyABookABTestServiceImpl.NewImportFlow.showPicture" value="B=0-899" /&gt;
  # <entry key="com.pronet.leo.bl.nus.impl.NetworkUpdatesABTestConstants.DiscussionEnabledForTypeID-APPM" value="A=0-999" />
    
      $mapping{$key}{$comp}{$latest_version} = $val; 
  
    }
  }

}



sub get_keyval {

  my $line = shift;

  chomp($line);

  my $key;
  my $val;

  if ( $line =~ m{entry key="(.*?)"\s+value="(.*)".*} && $line !~ m{&lt;!--} ) {
  
    $key = $1;
    $val = $2;
    
  }

  ($key, $val);

}



__END__


617      wget http://ech3-cfg01.prod.foobar.com:10094/healthcheck-console/config.jsp 
618      wget http://ech3-cfg01.prod.foobar.com:10094/healthcheck-console/config.jsp?config=/PROD-ECH3/lmt/0.0.505/extservices.springconfig -O lmt
