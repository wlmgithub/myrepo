#!/usr/bin/perl -wT
use strict;
use CGI qw(:standard);

use File::stat;
use Time::localtime;

print header();

print start_html(-title=>'ECH3 Health Dashboard - Owners Info',
                 -style => { -src => '/css/main.css',
                             -type => 'text/css',
                             -media => 'screen' },
                 );



print "<p style='font-size:200%; font-weight: bold; '> <img src='/images/NOC.jpg'  width = '250' height = '100' align ='middle' >  Service Owners  </p>";
#print h1("ECH3 Health Dashboard\n");


=for comment
while ( my ($k, $v) = each %ENV ) {
  print "<p> $k => $v\n";
}
=cut


### globals
my $OWNER_DIR = "/Library/WebServer/Documents/dashboard/data/owner";
my $OWNER_FILE = "owner_for_noc.txt";
my $SRE_FILE = "dept_to_sre.txt";

my %sre_of_dept; # dept => sre

### main


gen_dept_to_sre_mapping();


print hr();
print p();
print p();
print p();

print "<center>";
show_owners();
print "</center>";

print p();
print p();
print p();

show_footer();


sub show_owners {

  my $stamp = ctime(stat("$OWNER_DIR/$OWNER_FILE")->mtime);   # e.g. Tue Jul 19 14:14:10 2011
  print "<table>";
  print "<caption> Service Owners ( Last Updated: $stamp )  </caption>";
  print "<th> #  </th>";
  print "<th> Service  </th>";
  print "<th> Owner </th>";
  print "<th> Department </th>";
  print "<th> Manager </th>";
  print "<th> SRE </th>";


  my $sn;  # serial number for services
  # parse OWNER_FILE 
  open my $fh, "$OWNER_DIR/$OWNER_FILE" or die "cannot open file $OWNER_FILE to read: $!\n";
  while(<$fh>) {
    next if /^\s+$/;
    chomp;
    my ($service, $owner, $dept, $mgr) = split(/\|/);
    
    $sn++;

    # Liming Wang (lwang@foobar.com) -> Liming Wang
    $owner =~ s/\(.*\)//;
    $mgr =~ s/\(.*\)//;

    # cinco link
    # http://cinco.corp.foobar.com/profile?form_submitted=1&name=liming+wang
    my $cinco = 'http://cinco.corp.foobar.com/profile?form_submitted=1&name=';

    my $cinco_owner = get_cinco_link( $cinco, $owner); 
    my $cinco_mgr = get_cinco_link( $cinco, $mgr); 

#    my $owner_shown = $owner;
#    $owner_shown  =~ s/\(.*\)//;
#    my @owner_ary = split(/ /, $owner_shown);
#    my $owner_str = join('+', @owner_ary);
#    my $cinco_owner = $cinco . $owner_str;
#
    print "<tr>";
    print "<td> $sn </td>";
    print "<td> $service </td>";
    if ( $owner ) {
#      print "<td> $owner ( <a href=\"$cinco_owner\" target='_blank'> cinco </a> )</td>";
      print "<td> <a href='$cinco_owner' target='_blank'>  $owner  </a> </td>";
    } else {
      print "<td> </td>";
    }
    print "<td> $dept </td>";
    if ( $mgr ) {
#      print "<td> $mgr ( <a href=\"$cinco_mgr\" target='_blank'> cinco </a> )  </td>";
      print "<td> <a href=\"$cinco_mgr\" target='_blank'> $mgr </a>   </td>";
    } else {
      print "<td>  </td>";
    }
    print "<td> <a href='https://iwww.corp.foobar.com/wiki/cf/display/SOP/Siteops+and+NOC+Oncall+Rotation+Calendar' target='_blank'> $sre_of_dept{$dept} </a> </td>";
    print "</tr>";
  }
  close $fh;


  print "</table>";


}


sub get_cinco_link {

    my $cinco = shift;
    my $owner = shift;

    my $owner_shown = $owner;
    $owner_shown  =~ s/\(.*\)//;
    my @owner_ary = split(/ /, $owner_shown);
    my $owner_str = join('+', @owner_ary);
    my $cinco_owner = $cinco . $owner_str;

    return $cinco_owner;

}


sub gen_dept_to_sre_mapping {
  
  open my $fh, "$OWNER_DIR/$SRE_FILE" or die "cannot open $OWNER_DIR/$SRE_FILE for reading: $!\n";
  while(<$fh>) {
    chomp;
    next if /^\s*$/;
    next if /^#/;
    if ( /(.*)\s+:\s+(.*)/ ) {
      $sre_of_dept{$1} = $2;
    }
  }

  close $fh;

}



__END__
