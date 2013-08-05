package NOC;

use CGI qw(:standard);

use DBI;

our %labels_for_months = ( '00' => 'NA', '01'=>'Jan','02'=>'Feb','03'=>'Mar','04'=>'Apr','05'=>'May','06'=>'Jun','07'=>'Jul','08'=>'Aug','09'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec' );

#our $ldapServer = "ldaps://esv4-adc01.foobar.biz:3269";   # with the gal port (3269), you get a limited view into the AD data..
our $ldapServer = "ldaps://esv4-adc01.foobar.biz";
our $allowed_department_1 = "Site Operations";
our $allowed_department_2 = "Production Operations Infrastructure";
our $allowed_department_3 = "1110 - Product Ops Infrastructure";
our $http_proto = "https";

our $allowed_department_number_1 = 1130;  # "Site Operations"  : not including NOC
our $allowed_department_number_2 = 1110;  # "Production Operations Infrastructure" :  including NOC

sub show_header() {

}


sub show_footer() {

  print "<hr />";
#  print img( { -src => '/lwang/images/bottombar.png',  -align => 'center'  } );
#  print img( { -src => '/lwang/images/bottombar.png', -style => 'position:center,overflow; width: 1500; height: 20      '  } );
  print "<center>";
  print "<a href='https://iwww.corp.foobar.com/wiki/cf/display/NOC/Home' target='_blank'>  NOC Homepage </a>  ";
  print " | ";
  print "<a href='https://iwww.corp.foobar.com/wiki/cf/display/NOC/Global+Change+Notice+%28GCN%29+Board' target='_blank'> GCN Help </a> ";
  print " | ";
  print "Email: <a href='mailto:noc\@foobar.com'> noc\@foobar.com </a> ";
  print "</center>";

}


sub get_dbh {

  # database information
  my $db="noc";
  my $host="localhost";
  my $userid="root";
  my $passwd="password";
  my $connectionInfo="DBI:mysql:$db;$host";
  
  # make connection to database
  my $dbh = DBI->connect(
                $connectionInfo,$userid,$passwd,
                {PrintError => 1, RaiseError => 1 },
        );

  return $dbh;

}


###########################
use POSIX qw(strftime);
our $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

# Wed Jul 14 17:36:04 2010

=pod
my $current_day_of_week = get_current_day_of_week();
my $current_day = get_current_day();
my $current_month = get_current_month();
my $current_year = get_current_year();

my $current_hour = get_current_hour();
my $current_minute = get_current_minute();
my $current_second = get_current_second();

print "\n~~~~~~~~~~~~~~~~~~\n";

print "$current_day_of_week\n";
print "$current_day\n";
print "$current_month\n";
print "$current_year\n";

print "$current_hour\n";
print "$current_minute\n";
print "$current_second\n";
=cut


sub get_current_day_of_week {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  return $1 if $now_string =~ /(.*?) .*/;

}

sub get_current_day {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  return $1 if $now_string =~ /.*?\s+.*?\s+(.*?)\s+.*/;

}

sub get_current_month {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  return $1 if $now_string =~ /.*?\s+(.*?)\s+.*?\s+.*/;

}

sub get_current_year {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  return $1 if $now_string =~ /.*?\s+.*?\s+.*?\s+.*?\s+(.*)/;

}


sub get_current_hour {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  my $time_string = $1 if  $now_string =~ /.*?\s+.*?\s+.*?\s+(.*?)\s+.*/;

  return $1 if $time_string =~ /(.*?):.*?:.*/;

}

sub get_current_minute {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  my $time_string = $1 if  $now_string =~ /.*?\s+.*?\s+.*?\s+(.*?)\s+.*/;

  return $1 if $time_string =~ /.*?:(.*?):.*/;

}

sub get_current_second {

  my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

  my $time_string = $1 if  $now_string =~ /.*?\s+.*?\s+.*?\s+(.*?)\s+.*/;

  return $1 if $time_string =~ /.*?:.*?:(.*)/;

}

sub get_today {

  my ($Year, $Month, $Day) = (localtime)[5,4,3];
  $Month = sprintf("%02d", $Month);
  $Day = sprintf("%02d", $Day);
  $Month++;
  $Year += 1900;
  "$Year-$Month-$Day";

}

sub get_yesterday {

  my ($yYear, $yMonth, $yDay) = (localtime(time - 24 * 60 * 60))[5,4,3];
  $yMonth = sprintf("%02d", $yMonth);
  $yDay = sprintf("%02d", $yDay);
  $yMonth++;
  $yYear += 1900;
  "$yYear-$yMonth-$yDay";

}


######################## for LDAP
=pod

sub find_cn_of_user {

  my $username = shift;

  my $bind_string =  "cn=Active Directory Monitor Pseudo-User,ou=Pseudo-Users,dc=foobar,dc=biz";
  my $bindPass = 'password';

  
  my $ldap = Net::LDAP->new( $ldapServer ) or die "$@";

  $ldap->bind($bind_string, password => $bindPass);

  my $mesg = $ldap->search ( 
                        filter => "mailNickname=$username",
                        base => "ou=staff users,dc=foobar,dc=biz",
                        scope => 'sub',
                        attrs => 'cn');

  return if  $mesg->code();

  my @entries = $mesg->entries;

  foreach my $entry ( @entries ) {
    if ( $entry->get_value("department") eq "$allowed_department_1"  or  $entry->get_value("department") eq "$allowed_department_2" ) {
      return $entry->get_value("CN");
    }
    else {
      return;
    }
  }

}


sub password_ok {

  my $cn = shift;
  my $password = shift;

  my $bind_string =  "cn=$cn,ou=staff users,dc=foobar,dc=biz";
  my $bindPass = "$password";

  
  my $ldap = Net::LDAP->new( $ldapServer ) or die "$@";

  $ldap->bind($bind_string, password => $bindPass);

  my $mesg = $ldap->search ( 
                        filter => "mailNickname=$username",
                        base => "ou=staff users,dc=foobar,dc=biz",
                        scope => 'sub',
                        attrs => 'cn');

  return if  $mesg->code();

  my @entries = $mesg->entries;

  foreach my $entry ( @entries ) {
    if ( $entry->get_value("department") eq "$allowed_department_1"  or  $entry->get_value("department") eq "$allowed_department_2" ) {
      return $entry->get_value("CN");
    }
    else {
      return;
    }
  }

}

=cut

#######################
1;

