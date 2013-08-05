#!/usr/local/perl/bin/perl -wT
#!/bin/perl -wT
use strict;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

use lib '.';
use NOC;

use DBI;
use Net::LDAP;


my $ldapServer = $NOC::ldapServer;
my $allowed_department_number_1 = $NOC::allowed_department_number_1;
my $allowed_department_number_2 = $NOC::allowed_department_number_2;
my $http_proto = $NOC::http_proto;

my $server_name = $ENV{'SERVER_NAME'};
my $this_script = $ENV{'SCRIPT_NAME'};
my $view_script = '/cgi-bin/noc/outage/view.cgi';


print header();
print start_html(  
		-title => " Outage Board Fill Out Form ",  
		-style => {
			-src => ['/lwang/css/dhtmlgoodies_calendar.css', '/lwang/css/gcn.css'],
			-type => 'text/css',
			-media => 'screen',
		},
		-script => {
			-language => 'javascript',
			-src => '/lwang/js/dhtmlgoodies_calendar.js',
		},
	);


print img( { src => '/lwang/images/NOC.jpg', align => 'left' , width => '200', height => '100'} );


sub display_gcn_number_search {

  print start_form( -action => "${http_proto}://${server_name}${this_script}" );
#  print start_form( );

  my $username = param('username');
  my $password = param('password');
  print hidden( -name => 'form_submitted', -value => '1' );
  print hidden( -name => 'username', -value => "$username");
  print hidden( -name => 'password', -value => "$password");
  print "GCN#: ", textfield( -name => 'gcn_number', -id => 'gcn_number', -size => '10' ) ;
  print submit( -name => 'submit', -value => 'Search' );
#  print reset( -name => 'cancel', -value => 'Reset' );

  print end_form();

}

sub display_delete_form {

  print "<div id='delete_form'>";

  print start_form( -action => "${http_proto}://${server_name}${this_script}" );

  my $username = param('username');
  my $password = param('password');
  print hidden( -name => 'form_submitted', -value => '1' );
  print hidden( -name => 'username', -value => "$username");
  print hidden( -name => 'password', -value => "$password");
  print "<a title='if you have a bunch of GCNs, use a comma separated list, e.g., 1,2,3,4,5 '> <span class='help'>(help?)</span> </a> GCN(s) to delete: ", textfield( -name => 'gcns_to_delete', -id => 'gcns_to_delete', -size => '50' ) ;
  print submit( -name => 'submit', -value => 'Delete' ,  -onClick => "return confirm('Are you sure you want to delete the GCN(s)?');  "  );
#  print submit( -name => 'submit', -value => 'Delete' ,  -onClick => "alert('Are you sure you want to delete the GCN(s)?' + document.getElementById('gcns_to_delete').value ) "  );

  print end_form();

  print "</div>";

}


sub update_display_form {


  my (

	$id,
        $short_description,
        $criticality,
        $creator,
        $owner,
        $contact,
	$updated,
        $rt_ticket,
        $jira_ticket,
        $type,
        $impacted_services,
        $description,
        $end_user_instruction,
        $comments,
	$justnow,
	$created,
        $start_time,
        $detection_time,
        $est_end_time,
        $start_day_of_week,
        $detection_day_of_week,
        $end_day_of_week,
	$status,
	$responsible_group,
	$root_cause,

  ) =    @_ ;


  $rt_ticket ||= '';
  $jira_ticket ||= '';
  $impacted_services ||= '';
  $description ||= '';
  $end_user_instruction ||= '';
  $comments ||= ''; 
  $creator ||= '';
  $root_cause ||= '';


#  print p("in update_display_form ");
  print p();

  print start_form(  -action => "${http_proto}://${server_name}${this_script}", -id => 'update_display_form',  -name => 'update_display_form' );
#  print start_form(  -id => 'update_display_form',  -name => 'update_display_form' );
  print hr();

  my $username = param('username');
  my $password = param('password');
  print hidden( -name => 'form_submitted', -value => '1' );
  print hidden( -name => 'username', -value => "$username");
  print hidden( -name => 'password', -value => "$password");

  print p(b("GCN#: "), textfield( -name => "id", -id => "id", -default => $id, -readonly  => 'readonly' ) );
  print p(b("Short Description: "), textfield( -name => "short_description", -id => "short_description", -size => 128, -default => "$short_description" ));
  print p(b("RT Ticket Reference#: "), textfield( -name => "rt_ticket", -id => "rt_ticket", -size => 10, -default => "$rt_ticket"  ));
  print p(b("JIRA Ticket Reference#: "), textfield( -name => "jira_ticket", -id => "jira_ticket", -size => 10, -default => "$jira_ticket"  ));
  print p(b("Creator: "), textfield( -name => "creator", -id => "creator",  -size => 20, -default => "$creator"  ));
  print p(b("Owner Email: "), textfield( -name => "owner", -id => "owner",  -size => 20, -default => "$owner"  ));
  print p(b("Contact Email: "), textfield( -name => "contact", -id => "contact",  -default => "$contact", -size => 100 ));


  my %labels_for_outage_type = (
        'Planned' => 'Planned',
        'Unplanned' => 'Unplanned',
  );

  print b("<p />Outage Type: ");
  print popup_menu(
    -name => 'type',
    -id => 'type',
    -values => [ 'Planned', 'Unplanned' ],
    -default => "$type",
    -labels => \%labels_for_outage_type,
  );


  my %labels_for_criticality = (
        'Major' => 'Major',
        'Moderate' => 'Moderate',
        'Minor' => 'Minor',
  );

  print b("<p />Criticality: ");
  print popup_menu(
    -name => "criticality",
    -id => "criticality",
    -values => [ 'Major', 'Moderate', 'Minor' ],
    -default => "$criticality",
    -labels => \%labels_for_criticality,
  );

   my %labels_for_status = (
        'Pending' => 'Pending',
        'Closed' => 'Closed',
  );

  print b("<p />Status: ");
  print popup_menu(
    -name => "status",
    -id => "status",
    -values => [ 'Pending', 'Closed' ],
    -default => "$status",
    -labels => \%labels_for_status,
  );


  print p(b("Impacted Services/Servers: "), textfield( -name => "impacted_services", -id => "impacted_services", -size => 100, -default => "$impacted_services" ));


  print b("<p />Outage Start Time: ");
  update_display_time_popup_menu_start( $start_day_of_week, $start_time );


  print b("<p />Outage End Time: ");
  update_display_time_popup_menu_end( $end_day_of_week, $est_end_time );


  print b("<p />Outage Detection Time: ");
  update_display_time_popup_menu_detection( $detection_day_of_week, $detection_time );


  print "<p />";
  print b("Problem Description and Updates: <p />");

  print textarea(
    -name => 'description',
    -id => 'descrption',
    -default => "$description",
    -rows => 10,
    -cols => 100,

  );

  print "<p />";
  print b("End User Instructions: <p />");

  print textarea(
    -name => 'end_user_instruction',
    -id => 'end_user_instruction',
    -default => "$end_user_instruction",
    -rows => 10,
    -cols => 100,

  );

  print "<p />";
  print b("<font color='red'> When you close a GCN, please fill out the following fields:</font> <p />");


=pod
  print b("Comments: <p />");

  print textarea(
    -name => 'comments',
    -id => 'comments',
    -default => "$comments",
    -rows => 10,
    -cols => 100,

  );
=cut

  print "<p />";


  my %labels_for_responsible_group = (
        'AppOps' => 'AppOps',
        'DBA' => 'DBA',
        'NetOps' => 'NetOps',
        'SysOps' => 'SysOps',
  );

  my @responsible_group = keys %labels_for_responsible_group;
  my $responsible_group_ref_default = \@responsible_group;

  if ( $responsible_group ) {
    my @a = split(' ', $responsible_group);
    $responsible_group_ref_default  = \@a;
  }

  print "<p />";
  print b("Responsible Group: ");
#  print textfield( -name => "responsible_group", -id => "responsible_group", -default => "$responsible_group", -size => 100);
  print scrolling_list( 
    -name => "responsible_group",
    -id => "responsible_group",
    -default => $responsible_group_ref_default,
    -size => 4,
    -multiple => 'true',
    -values => \@responsible_group,
    -labels => \%labels_for_responsible_group,
  );

  print "<p />";
  print b("Root Cause: ");
#  print textfield( -name => "root_cause", -id => "root_cause", -default => "$root_cause", -size => 100);
  print textarea(
    -name => 'root_cause',
    -id => 'root_cause',
    -default => "$root_cause",
    -rows => 3,
    -cols => 100,

  );


  print "<p />";
  print "<p />";
  print "<p />";

  print submit( -NAME => "submit", -VALUE => "Update" );
  print reset( -NAME => "cancel", -VALUE => "Reset" );

  print end_form();


}

sub update_gcn {

  my $id = shift;

  my $dbh = NOC::get_dbh();
  
  # prepare and execute query

  my $query = qq[
                SELECT
                id, short_description, criticality,  rt_ticket, jira_ticket,  type,   impacted_services,  description,   end_user_instruction ,  comments , creator, owner  , contact , justnow , created ,
                updated, start_time, est_end_time, detection_time, start_day_of_week, end_day_of_week, detection_day_of_week,  status, responsible_group, root_cause

                FROM outage where id = ?
                ];

  my $sth = $dbh->prepare($query) or die "stmt error: " . $dbh->errstr;;
  $sth->execute( $id  );
  
  # assign fields to variables
  my ( $short_description, $criticality, $creator, $owner, $contact, $updated);
  my $rt_ticket;
  my $jira_ticket;
  my $type;
  my $impacted_services;
  my $description;
  my $end_user_instruction;
  my $comments;
  my $justnow;
  my $created;
  my $start_time;
  my $detection_time;
  my $est_end_time;
  my $start_day_of_week;
  my $detection_day_of_week;
  my $end_day_of_week;
  my $status;
  my $responsible_group;
  my $root_cause;


  $sth->bind_columns(\$id, \$short_description, \$criticality, \$rt_ticket, \$jira_ticket, \$type, \$impacted_services, \$description, \$end_user_instruction, \$comments,  \$creator, \$owner, \$contact, \$justnow, \$created, \$updated, 
	\$start_time, \$est_end_time, \$detection_time,  \$start_day_of_week, \$end_day_of_week, \$detection_day_of_week,  \$status, \$responsible_group, \$root_cause
  );

  
  # output to the browser 
  
  my $record_exists;
  while ( $sth->fetch() ) {

    print h1( " <center> GCN(Outage Board) Update Form </center>" );
    print p();
    print p("update GCN# $id ");

    update_display_form(

	$id,
	$short_description, $criticality, $creator, $owner, $contact, $updated,
	$rt_ticket,
	$jira_ticket,
	$type,
	$impacted_services,
	$description,
	$end_user_instruction,
	$comments,
	$justnow,
	$created,
	$start_time,
	$detection_time,
	$est_end_time,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$status,
	$responsible_group,
	$root_cause,

    );

    $record_exists++;

  }

  unless ( $record_exists ) {

    print h3("Oops,  I did not find the GCN# you  provided. Are you sure it's valid?");

  }
 
  print "</table>\n";
  print "</body>\n";
  print "</html>\n";
  
  $sth->finish();
  
  # disconnect from database
  $dbh->disconnect;
  
  NOC::show_footer();

  exit;

}


sub display_form() {

  print start_form( -action => "${http_proto}://${server_name}${this_script}", -id => 'display_form',  -name => 'display_form' );
#  print start_form( -id => 'display_form',  -name => 'display_form' );
  print hr();
  print p();
#  print img( { -src => '/lwang/images/topBar1.png', -style => 'position:center,overflow; width: 1500; height: 20      '  } );

=pod
print table({-border=>undef},
caption('When Should You Eat Your Vegetables?'),
Tr({-align=>'CENTER',-valign=>'TOP'},
[
th(['Vegetable', 'Breakfast','Lunch','Dinner']),
td(['Tomatoes' , 'no', 'yes', 'yes']),
td(['Broccoli' , 'no', 'no', 'yes']),
td(['Onions' , 'yes','yes', 'yes'])
]
)
);
=cut

  my $creator = param("username");

  my $username = param('username');
  my $password = param('password');
  print hidden( -name => 'form_submitted', -value => '1' );
  print hidden( -name => 'username', -value => "$username");
  print hidden( -name => 'password', -value => "$password");


#
# a better way to do it might be using  css:
#	http://www.pixy.cz/blogg/clanky/css-fieldsetandlabels.html
#
  print "<table>";
  print "<tr align='left'><td> <b>Short Description:</b> </td><td>" .  textfield( -name => "short_description", -id => "short_description", -size => 128) . "</td></tr>";
#  print "<tr align='left'><td> <b>RT Ticket Reference#:</b> </td><td>" . textfield( -name => "rt_ticket", -id => "rt_ticket", -size => 10 ) . " &nbsp; (e.g., 1234)</td> </tr>";
#  print "<tr align='left'><td> <b>JIRA Ticket Reference#:</b> </td><td>" . textfield( -name => "jira_ticket", -id => "jira_ticket", -size => 10 ) . " &nbsp;  (e.g., PROD-1234) </td></tr>";
  print "<tr align='left'><td> <b>RT Ticket Reference#:</b> </td><td>" . textfield( -name => "rt_ticket", -id => "rt_ticket", -size => 10 ) . " &nbsp; (e.g., 1234)  &nbsp; --or-- &nbsp; ";
  print " <b>JIRA Ticket Reference#:</b> " . textfield( -name => "jira_ticket", -id => "jira_ticket", -size => 10 ) . " &nbsp;  (e.g., PROD-1234) </td></tr>";
  print "<tr align='left'><td>" .  b("Creator: ") . "</td><td>" .  textfield( -name => "creator", -id => "creator",  -size => 20, -default => "$creator\@foobar.com", -readonly => 'readonly'  ) . "</td></tr>";
  print "<tr align='left'><td>" .  b("Owner Email: ") . "</td><td>" .  textfield( -name => "owner", -id => "owner",  -size => 20 ) . "</td></tr>";
  print "<tr align='left'><td>" .  b("Contact Email: ") . "</td><td>" .  textfield( -name => "contact", -id => "contact",  -default => 'noc@foobar.com', -size => 100 ) .  "</td></tr>";


  my %labels_for_outage_type = (
	'Planned' => 'Planned',	
	'Unplanned' => 'Unplanned',	
  );

  print  "<tr align='left'><td>" .  b("<p />Outage Type: ");
  print "</td><td>" . popup_menu(
    -name => 'type',
    -id => 'type',
    -values => [ 'Planned', 'Unplanned' ],
    -default => 'Planned',
    -labels => \%labels_for_outage_type,
  );
  print "</td></tr>";
  

  my %labels_for_criticality = ( 
	'Major' => 'Major',
	'Moderate' => 'Moderate',
	'Minor' => 'Minor',
  );

  print "<tr align='left'><td>" . b("Criticality: "); 
  print "</td><td>" . popup_menu(
    -name => "criticality",
    -id => "criticality",
    -values => [ 'Major', 'Moderate', 'Minor' ],
    -default => 'Minor',
    -labels => \%labels_for_criticality,
  );
  print "</td></tr>";

	


  print "<tr align='left'><td>" . b("<p />Impacted Services/Servers: ") . "</td><td>" .   textfield( -name => "impacted_services", -id => "impacted_services", -size => 100) . "</td></tr>";


  print "<tr align='left'><td>" . b("<p />Outage Start Time: ");
  print  "</td><td>" ;  
  display_time_popup_menu_start();
  print "</td></tr>";


  print "<tr align='left'><td>" .  b("<p />Outage End Time: ");
  print  "</td><td>" ;  
  display_time_popup_menu_end();
  print "</td></tr> ";


  print "<tr align='left'><td>" . b("<p />Outage Detection Time: ");
  print  "</td><td>" ;  
  display_time_popup_menu_detection();
  print "</td></tr>";


  print "<tr align='left'><td>" ;
  print  b("<p />Problem Description and Updates: <p />");
  print  "</td><td>" ;
  print textarea(
    -name => 'description',
    -id => 'descrption',
    -default => 'problem description and updates',
    -rows => 10,
    -cols => 100,

  );
  print "</td></tr>";


  print "<tr align='left'><td>";
  print b("End User Instructions: <p />");
  print  "</td><td>" ;
  print textarea(
    -name => 'end_user_instruction',
    -id => 'end_user_instruction',
    -default => '',
    -rows => 10,
    -cols => 100,

  );
  print "</td></tr>";


=pod
  print "<tr align='left'><td>";
  print b("Comments: <p />");
  print  "</td><td>" ;
  print textarea(
    -name => 'comments',
    -id => 'comments',
    -default => 'your comments here',
    -rows => 10,
    -cols => 100,

  );
=cut

  print "</td></tr>";


  print "<p />";
  print "<p />";
  print "<p />";

  print "<tr align='left'><td>";
  print  "</td><td>" ;
  print submit( -NAME => "submit", -VALUE => "Submit" );
  print reset( -NAME => "cancel", -VALUE => "Reset" );
  print "</td></tr>";


  print "</table>";


  print end_form();
  print p();

}

sub update_display_time_popup_menu_detection {

  my $detection_day_of_week = shift;
  my $detection_time = shift;

  my $default_year;
  my $default_day;
  my $default_month;

  my $default_hour;
  my $default_minute;
  my $default_second;

  if ( $detection_time ) {
    if ( $detection_time =~  m{(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})} ) {
   
      $default_year = $1;
      $default_month = $2;
      $default_day = $3;
      $default_hour = $4;
      $default_minute = $5;
      $default_second = $6;
  
    } 
  }


  my @years = qw(
    2010
    2011
    2012
    2013
    2014
    2015
  );

  my @months;
  for ( 1..12) {
    push @months, sprintf("%02s", $_);
  }
#  my %labels_for_months = ( '01'=>'Jan','02'=>'Feb','03'=>'Mar','04'=>'Apr','05'=>'May','06'=>'Jun','07'=>'Jul','08'=>'Aug','09'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec' );

  my @days;
  for ( 1 .. 31 ) {
    push @days, sprintf("%02s", $_);
  }

  my @hours;
  for ( 0 .. 23 ) {
    push @hours, sprintf("%02s", $_);
  }

  my @minutes;
  for ( 0 .. 59 ) {
    push @minutes, sprintf("%02s", $_);
  }

  my @seconds;
  for ( 0 .. 59 ) {
    push @seconds, sprintf("%02s", $_);
  }

  my @weeks =  qw( Mon Tue Wed Thu Fri Sat Sun ) ; 


  print popup_menu(
    -name => "detection_day_of_week",
    -id => "detection_day_of_week",
    -values => \@weeks,
    -default => $detection_day_of_week,
  );

  print popup_menu(
    -name => 'detection_day',
    -id => 'detection_day',
    -values => \@days,
    -default => $default_day,
  );

  print popup_menu(
    -name => 'detection_month',
    -id => 'detection_month',
    -values => \@months,
    -default => $default_month,
    -labels => \%NOC::labels_for_months,
  );

  print popup_menu(
    -name => 'detection_year',
    -id => 'detection_year',
    -values => \@years,
    -default => $default_year,
  );


  print " : ";


  print popup_menu(
    -name => 'detection_hour',
    -id => 'detection_hour',
    -values => \@hours,
    -default => $default_hour,
  );

  print popup_menu(
    -name => 'detection_minute',
    -id => 'detection_minute',
    -values => \@minutes,
    -default => $default_minute,
  );


  print hidden( popup_menu(
    -name => 'detection_second',
    -id => 'detection_second',
    -values => \@seconds,
    -default => $default_second,
  ) );

  print " (Pacific Time)";


  print button(
    -name => 'calendar',
    -value => 'Cal',
    -src => '/lwang/images/calendar_button.png',
    -onClick => "displayCalendarSelectBox(document.getElementById('update_display_form').detection_year, document.getElementById('update_display_form').detection_month, document.getElementById('update_display_form').detection_day, document.getElementById('update_display_form').detection_hour, document.getElementById('update_display_form').detection_minute, document.getElementById('update_display_form').detection_day_of_week,  this)",
  );


}

sub update_display_time_popup_menu_start {

  my $start_day_of_week = shift;
  my $start_time = shift;

  my $default_year;
  my $default_day;
  my $default_month;

  my $default_hour;
  my $default_minute;
  my $default_second;

  if ( $start_time =~  m{(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})} ) {
 
    $default_year = $1;
    $default_month = $2;
    $default_day = $3;
    $default_hour = $4;
    $default_minute = $5;
    $default_second = $6;

  } 


  my @years = qw(
    2010
    2011
    2012
    2013
    2014
    2015
  );

  my @months;
  for ( 1..12) {
    push @months, sprintf("%02s", $_);
  }
#  my %labels_for_months = ( '01'=>'Jan','02'=>'Feb','03'=>'Mar','04'=>'Apr','05'=>'May','06'=>'Jun','07'=>'Jul','08'=>'Aug','09'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec' );

  my @days;
  for ( 1 .. 31 ) {
    push @days, sprintf("%02s", $_);
  }

  my @hours;
  for ( 0 .. 23 ) {
    push @hours, sprintf("%02s", $_);
  }

  my @minutes;
  for ( 0 .. 59 ) {
    push @minutes, sprintf("%02s", $_);
  }

  my @seconds;
  for ( 0 .. 59 ) {
    push @seconds, sprintf("%02s", $_);
  }

  my @weeks =  qw( Mon Tue Wed Thu Fri Sat Sun ) ; 


  print popup_menu(
    -name => "start_day_of_week",
    -id => "start_day_of_week",
    -values => \@weeks,
    -default => $start_day_of_week,
  );

  print popup_menu(
    -name => 'start_day',
    -id => 'start_day',
    -values => \@days,
    -default => $default_day,
  );

  print popup_menu(
    -name => 'start_month',
    -id => 'start_month',
    -values => \@months,
    -default => $default_month,
    -labels => \%NOC::labels_for_months,
  );

  print popup_menu(
    -name => 'start_year',
    -id => 'start_year',
    -values => \@years,
    -default => $default_year,
  );


  print " : ";


  print popup_menu(
    -name => 'start_hour',
    -id => 'start_hour',
    -values => \@hours,
    -default => $default_hour,
  );

  print popup_menu(
    -name => 'start_minute',
    -id => 'start_minute',
    -values => \@minutes,
    -default => $default_minute,
  );


  print hidden( popup_menu(
    -name => 'start_second',
    -id => 'start_second',
    -values => \@seconds,
    -default => $default_second,
  ) );

  print " (Pacific Time)";


  print button(
    -name => 'calendar',
    -value => 'Cal',
    -src => '/lwang/images/calendar_button.png',
    -onClick => "displayCalendarSelectBox(document.getElementById('update_display_form').start_year, document.getElementById('update_display_form').start_month, document.getElementById('update_display_form').start_day, document.getElementById('update_display_form').start_hour, document.getElementById('update_display_form').start_minute, document.getElementById('update_display_form').start_day_of_week,  this)",
  );

}


sub display_time_popup_menu_detection {

  # default to today's date and time now()

  my $current_day_of_week = NOC::get_current_day_of_week();
  my $current_day = sprintf("%02s", NOC::get_current_day());
  my $current_month = NOC::get_current_month();
  my $current_year = NOC::get_current_year();
  
  my $current_hour = NOC::get_current_hour();
  my $current_minute = NOC::get_current_minute();
  my $current_second = NOC::get_current_second();

  my @years = qw(
    2010
    2011
    2012
    2013
    2014
    2015
  );

  my @months;
  for ( 1..12) {
    push @months, sprintf("%02s", $_);
  }
#  my %labels_for_months = ( '01'=>'Jan','02'=>'Feb','03'=>'Mar','04'=>'Apr','05'=>'May','06'=>'Jun','07'=>'Jul','08'=>'Aug','09'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec' );

  my @days;
  for ( 1 .. 31 ) {
    push @days, sprintf("%02s", $_);
  }

  my @hours;
  for ( 0 .. 23 ) {
    push @hours, sprintf("%02s", $_);
  }

  my @minutes;
  for ( 0 .. 59 ) {
    push @minutes, sprintf("%02s", $_);
  }

  my @seconds;
  for ( 0 .. 59 ) {
    push @seconds, sprintf("%02s", $_);
  }

  my @weeks =  qw( Mon Tue Wed Thu Fri Sat Sun ) ; 


  print popup_menu(
    -name => "detection_day_of_week",
    -id => "detection_day_of_week",
    -values => \@weeks,
    -default => $current_day_of_week,
  );



  print popup_menu(
    -name => 'detection_day',
    -id => 'detection_day',
    -values => \@days,
    -default => $current_day,
  );

  my %h = reverse %NOC::labels_for_months;
  
  $current_month = $h{$current_month};

  print popup_menu(
    -name => 'detection_month',
    -id => 'detection_month',
    -values => \@months,
    -default => $current_month,
    -labels => \%NOC::labels_for_months,
  );
#    -default => '01',

  print popup_menu(
    -name => 'detection_year',
    -id => 'detection_year',
    -values => \@years,
    -default => $current_year,
  );


  print " : ";


  print popup_menu(
    -name => 'detection_hour',
    -id => 'detection_hour',
    -values => \@hours,
    -default => $current_hour,
  );

  print popup_menu(
    -name => 'detection_minute',
    -id => 'detection_minute',
    -values => \@minutes,
    -default => $current_minute,
  );


  print hidden( popup_menu(
    -name => 'detection_second',
    -id => 'detection_second',
    -values => \@seconds,
    -default => $current_second,
  ) );

  print " (Pacific Time)";


  print button(
    -name => 'calendar',
    -value => 'Cal',
    -src => '/lwang/images/calendar_button.png',
    -onClick => "displayCalendarSelectBox(document.getElementById('display_form').detection_year, document.getElementById('display_form').detection_month, document.getElementById('display_form').detection_day, document.getElementById('display_form').detection_hour, document.getElementById('display_form').detection_minute, document.getElementById('display_form').detection_day_of_week,  this)",
  );


}


sub display_time_popup_menu_start {

  # default to today's date and time now()

  my $current_day_of_week = NOC::get_current_day_of_week();
  my $current_day = sprintf("%02s", NOC::get_current_day());
  my $current_month = NOC::get_current_month();
  my $current_year = NOC::get_current_year();
  
  my $current_hour = NOC::get_current_hour();
  my $current_minute = NOC::get_current_minute();
  my $current_second = NOC::get_current_second();

  my @years = qw(
    2010
    2011
    2012
    2013
    2014
    2015
  );

  my @months;
  for ( 1..12) {
    push @months, sprintf("%02s", $_);
  }
#  my %labels_for_months = ( '01'=>'Jan','02'=>'Feb','03'=>'Mar','04'=>'Apr','05'=>'May','06'=>'Jun','07'=>'Jul','08'=>'Aug','09'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec' );

  my @days;
  for ( 1 .. 31 ) {
    push @days, sprintf("%02s", $_);
  }

  my @hours;
  for ( 0 .. 23 ) {
    push @hours, sprintf("%02s", $_);
  }

  my @minutes;
  for ( 0 .. 59 ) {
    push @minutes, sprintf("%02s", $_);
  }

  my @seconds;
  for ( 0 .. 59 ) {
    push @seconds, sprintf("%02s", $_);
  }

  my @weeks =  qw( Mon Tue Wed Thu Fri Sat Sun ) ; 


  print popup_menu(
    -name => "start_day_of_week",
    -id => "start_day_of_week",
    -values => \@weeks,
    -default => $current_day_of_week,
  );



  print popup_menu(
    -name => 'start_day',
    -id => 'start_day',
    -values => \@days,
    -default => $current_day,
  );

  my %h = reverse %NOC::labels_for_months;
  
  $current_month = $h{$current_month};

  print popup_menu(
    -name => 'start_month',
    -id => 'start_month',
    -values => \@months,
    -default => $current_month,
    -labels => \%NOC::labels_for_months,
  );
#    -default => '01',

  print popup_menu(
    -name => 'start_year',
    -id => 'start_year',
    -values => \@years,
    -default => $current_year,
  );


  print " : ";


  print popup_menu(
    -name => 'start_hour',
    -id => 'start_hour',
    -values => \@hours,
    -default => $current_hour,
  );

  print popup_menu(
    -name => 'start_minute',
    -id => 'start_minute',
    -values => \@minutes,
    -default => $current_minute,
  );


  print hidden( popup_menu(
    -name => 'start_second',
    -id => 'start_second',
    -values => \@seconds,
    -default => $current_second,
  ) );

  print " (Pacific Time)";


  print button(
    -name => 'calendar',
    -value => 'Cal',
    -src => '/lwang/images/calendar_button.png',
    -onClick => "displayCalendarSelectBox(document.getElementById('display_form').start_year, document.getElementById('display_form').start_month, document.getElementById('display_form').start_day, document.getElementById('display_form').start_hour, document.getElementById('display_form').start_minute, document.getElementById('display_form').start_day_of_week,  this)",
  );


}

sub update_display_time_popup_menu_end {

  my $end_day_of_week = shift;
  my $est_end_time = shift;

  my $default_year;
  my $default_day;
  my $default_month;

  my $default_hour;
  my $default_minute;
  my $default_second;

  if ( $est_end_time =~  m{(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})} ) {
 
    $default_year = $1;
    $default_month = $2;
    $default_day = $3;
    $default_hour = $4;
    $default_minute = $5;
    $default_second = $6;

  } 


  my @years = qw(
    2010
    2011
    2012
    2013
    2014
    2015
  );

  my @months;
  for ( 1..12) {
    push @months, sprintf("%02s", $_);
  }

  my @days;
  for ( 0 .. 31 ) {
    push @days, sprintf("%02s", $_);
  }

  my @hours;
  for ( 0 .. 23 ) {
    push @hours, sprintf("%02s", $_);
  }

  my @minutes;
  for ( 0 .. 59 ) {
    push @minutes, sprintf("%02s", $_);
  }

  my @seconds;
  for ( 0 .. 59 ) {
    push @seconds, sprintf("%02s", $_);
  }

  my @weeks =  qw( NA Mon Tue Wed Thu Fri Sat Sun ) ; 


  print popup_menu(
    -name => "end_day_of_week",
    -id => "end_day_of_week",
    -values => \@weeks,
    -default => $end_day_of_week,
  );


  print popup_menu(
    -name => 'end_day',
    -id => 'end_day',
    -values => \@days,
    -default => $default_day,
  );

  print popup_menu(
    -name => 'end_month',
    -id => 'end_month',
    -values => \@months,
    -default => $default_month,
    -labels => \%NOC::labels_for_months,
  );

  print popup_menu(
    -name => 'end_year',
    -id => 'end_year',
    -values => \@years,
    -default => $default_year,
  );


  print " : ";


  print popup_menu(
    -name => 'end_hour',
    -id => 'end_hour',
    -values => \@hours,
    -default => $default_hour,
  );

  print popup_menu(
    -name => 'end_minute',
    -id => 'end_minute',
    -values => \@minutes,
    -default => $default_minute,
  );


  print hidden( popup_menu(
    -name => 'end_second',
    -id => 'end_second',
    -values => \@seconds,
    -default => $default_second,
  ) );

  print " (Pacific Time)";

  print button(
    -name => 'calendar',
    -value => 'Cal',
    -src => '/lwang/images/calendar_button.png',
    -onClick => "displayCalendarSelectBox(document.getElementById('update_display_form').end_year, document.getElementById('update_display_form').end_month, document.getElementById('update_display_form').end_day, document.getElementById('update_display_form').end_hour, document.getElementById('update_display_form').end_minute, document.getElementById('update_display_form').end_day_of_week,  this)",
  );


}


sub display_time_popup_menu_end {

  # default to today's date and time now()

  my $current_day_of_week = NOC::get_current_day_of_week();
  my $current_day = sprintf("%02s", NOC::get_current_day());
  my $current_month = NOC::get_current_month();
  my $current_year = NOC::get_current_year();

  my $current_hour = NOC::get_current_hour();
  my $current_minute = NOC::get_current_minute();
  my $current_second = NOC::get_current_second();

  my @years = qw(
    2010
    2011
    2012
    2013
    2014
    2015
  );

  my @months;
  for ( 1 .. 12) {
    push @months, sprintf("%02s", $_);
  }

  my @days;
  for ( 0 .. 31 ) {
    push @days, sprintf("%02s", $_);
  }

  my @hours;
  for ( 0 .. 23 ) {
    push @hours, sprintf("%02s", $_);
  }

  my @minutes;
  for ( 0 .. 59 ) {
    push @minutes, sprintf("%02s", $_);
  }

  my @seconds;
  for ( 0 .. 59 ) {
    push @seconds, sprintf("%02s", $_);
  }

  my @weeks =  qw( NA  Mon Tue Wed Thu Fri Sat Sun ) ; 


  print popup_menu(
    -name => "end_day_of_week",
    -id => "end_day_of_week",
    -values => \@weeks,
    -default => $current_day_of_week,
  );


  print popup_menu(
    -name => 'end_day',
    -id => 'end_day',
    -values => \@days,
    -default => $current_day,
  );

  my %h = reverse %NOC::labels_for_months;

  $current_month = $h{$current_month};

  print popup_menu(
    -name => 'end_month',
    -id => 'end_month',
    -values => \@months,
    -default => $current_month,
    -labels => \%NOC::labels_for_months,
  );

  print popup_menu(
    -name => 'end_year',
    -id => 'end_year',
    -values => \@years,
    -default => $current_year,
  );


  print " : ";


  print popup_menu(
    -name => 'end_hour',
    -id => 'end_hour',
    -values => \@hours,
    -default => $current_hour,
  );

  print popup_menu(
    -name => 'end_minute',
    -id => 'end_minute',
    -values => \@minutes,
    -default => $current_minute,
  );


  print hidden( popup_menu(
    -name => 'end_second',
    -id => 'end_second',
    -values => \@seconds,
    -default => $current_second,
  ) );

  print " (Pacific Time)";

  print button(
    -name => 'calendar',
    -value => 'Cal',
    -src => '/lwang/images/calendar_button.png',
    -onClick => "displayCalendarSelectBox(document.getElementById('display_form').end_year, document.getElementById('display_form').end_month, document.getElementById('display_form').end_day, document.getElementById('display_form').end_hour, document.getElementById('display_form').end_minute,  document.getElementById('display_form').end_day_of_week,   this)",
  );

}


sub validate_form() {

#######   http://www.elated.com/articles/form-validation-with-perl-and-cgi/

  my $status = param("status") || '';
  my @responsible_group = param("responsible_group");
  my $root_cause = param("root_cause");

  ############################################################################
  # make sure responsible_group and status are filled in when status = 'Closed'
  ############################################################################
  if ( $status eq 'Closed' ) {
    $root_cause =~ s/\s+//g if $root_cause;
    unless ( @responsible_group and $root_cause ) {
      print '<font color="red"> You need to fill out "Responsible Group" and "Root Cause" fields. </font>';
      return;
    }
  }

  return 1; 
#  return; 

}


sub update_process_form() {

  my $gcn = param("id");

  my $short_description = param("short_description");
  my $rt_ticket = param("rt_ticket");
  my $jira_ticket = param("jira_ticket");
  my $creator = param("creator");
  my $owner = param("owner");
  my $contact = param("contact");
  my $type = param("type");
  my $criticality = param("criticality");
  my $impacted_services = param("impacted_services");
  my $description = param("description");
  my $end_user_instruction = param("end_user_instruction");
  my $comments = param("comments");
  my $status = param("status");
  my @responsible_group = param("responsible_group");
  my $responsible_group = join(' ', @responsible_group);
  my $root_cause = param("root_cause");

  my $start_day_of_week = param("start_day_of_week");
  my $detection_day_of_week = param("detection_day_of_week");
  my $end_day_of_week = param("end_day_of_week");

  my $start_year = param("start_year");
  my $start_month = param("start_month");
  my $start_day = param("start_day");
  my $start_hour = param("start_hour");
  my $start_minute = param("start_minute");
  my $start_second = param("start_second") || '00';
  my $start_time = "${start_year}-${start_month}-${start_day} ${start_hour}:${start_minute}:${start_second}";

  my $end_year = param("end_year");
  my $end_month = param("end_month");
  my $end_day = param("end_day");
  my $end_hour = param("end_hour");
  my $end_minute = param("end_minute");
  my $end_second = param("end_second") || '00';
  my $end_time = "${end_year}-${end_month}-${end_day} ${end_hour}:${end_minute}:${end_second}";

  my $detection_year = param("detection_year");
  my $detection_month = param("detection_month");
  my $detection_day = param("detection_day");
  my $detection_hour = param("detection_hour");
  my $detection_minute = param("detection_minute");
  my $detection_second = param("detection_second") || '00';
  my $detection_time = "${detection_year}-${detection_month}-${detection_day} ${detection_hour}:${detection_minute}:${detection_second}";

  $comments ||= '';

  if ( validate_form() ) {

    print <<MSG;
  
    GCN#: $gcn <p>
    short_description:  $short_description <p>
    rt_ticket :  $rt_ticket <p>
    jira_ticket :  $jira_ticket <p>
    creator :  $creator <p>
    owner :  $owner <p>
    contact :  $contact  <p>
    type :  $type  <p>
    criticality :  $criticality  <p>
    impacted_services :  $impacted_services  <p>
    description: $description <p>
    end_user_instruction: $end_user_instruction <p>
    comments: $comments <p>
    start_day_of_week: $start_day_of_week <p>
    detection_day_of_week: $detection_day_of_week <p>
    end_day_of_week: $end_day_of_week <p>
    start_time: $start_time <p>
    detection_time: $detection_time <p>
    end_time: $end_time <p>
    

MSG

    # if form is validated, insert into db

    my $rc = update_db(

	$gcn,
  	$short_description,
  	$rt_ticket,
  	$jira_ticket,
  	$creator,
  	$owner,
  	$contact,
  	$type,
  	$criticality,
  	$impacted_services,
  	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	$status,
	$responsible_group,
	$root_cause,
	
  	
    );

    # once updated, show view link
    print hr();
    print a( { -href => "${http_proto}://${server_name}${view_script}" },  "Visit the dash board" );

    die "cannot update record." unless $rc;

    # and send email too
    send_email( 

	"Updated",
	$gcn,
  	$short_description,
  	$rt_ticket,
  	$jira_ticket,
  	$creator,
  	$owner,
  	$contact,
  	$type,
  	$criticality,
  	$impacted_services,
  	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	$status,
	$responsible_group,
	$root_cause,
	
    );

  }
  else {

    show_form_not_valid_msg();

  }

}


sub process_form() {

  my $short_description = param("short_description");
  my $rt_ticket = param("rt_ticket");
  my $jira_ticket = param("jira_ticket");
  my $creator = param("creator");
  my $owner = param("owner");
  my $contact = param("contact");
  my $type = param("type");
  my $criticality = param("criticality");
  my $impacted_services = param("impacted_services");
  my $description = param("description");
  my $end_user_instruction = param("end_user_instruction");
  my $comments = param("comments") || '';

  my $start_day_of_week = param("start_day_of_week");
  my $detection_day_of_week = param("detection_day_of_week");
  my $end_day_of_week = param("end_day_of_week");

  my $start_year = param("start_year");
  my $start_month = param("start_month");
  my $start_day = param("start_day");
  my $start_hour = param("start_hour");
  my $start_minute = param("start_minute");
  my $start_second = param("start_second") || '00';
  my $start_time = "${start_year}-${start_month}-${start_day} ${start_hour}:${start_minute}:${start_second}";

  my $end_year = param("end_year");
  my $end_month = param("end_month");
  my $end_day = param("end_day");
  my $end_hour = param("end_hour");
  my $end_minute = param("end_minute");
  my $end_second = param("end_second") || '00';
  my $end_time = "${end_year}-${end_month}-${end_day} ${end_hour}:${end_minute}:${end_second}";

  my $detection_year = param("detection_year");
  my $detection_month = param("detection_month");
  my $detection_day = param("detection_day");
  my $detection_hour = param("detection_hour");
  my $detection_minute = param("detection_minute");
  my $detection_second = param("detection_second") || '00';
  my $detection_time = "${detection_year}-${detection_month}-${detection_day} ${detection_hour}:${detection_minute}:${detection_second}";

  my $status = "Pending";  # status  = 'Pending' at creation time

  if ( validate_form() ) {

    print <<MSG;
  
    short_description:  $short_description <p>
    rt_ticket :  $rt_ticket <p>
    jira_ticket :  $jira_ticket <p>
    creator :  $creator <p>
    owner :  $owner <p>
    contact :  $contact  <p>
    type :  $type  <p>
    criticality :  $criticality  <p>
    impacted_services :  $impacted_services  <p>
    description: $description <p>
    end_user_instruction: $end_user_instruction <p>
    comments: $comments <p>
    start_day_of_week: $start_day_of_week <p>
    detection_day_of_week: $detection_day_of_week <p>
    end_day_of_week: $end_day_of_week <p>
    start_time: $start_time <p>
    detection_time: $detection_time <p>
    end_time: $end_time <p>
    

MSG


    # if form is validated, insert into db

    my $last_insert_id = insert_into_db(

  	$short_description,
  	$rt_ticket,
  	$jira_ticket,
  	$creator,
  	$owner,
  	$contact,
  	$type,
  	$criticality,
  	$impacted_services,
  	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	
  	
    );

    # once inserted, show view link
    print hr();
    print a( { -href => "${http_proto}://${server_name}${view_script}" },  "Visit the dash board" );

    # and send email too
    send_email(

	"Created",
	$last_insert_id,
  	$short_description,
  	$rt_ticket,
  	$jira_ticket,
  	$creator,
  	$owner,
  	$contact,
  	$type,
  	$criticality,
  	$impacted_services,
  	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	$status,
	
    );

  }
  else {

    show_form_not_valid_msg();

  }

}

sub show_form_not_valid_msg {

    print h2("form not validated, please go back and try again if you want.");

}


sub get_time_fragments {

  my $time_string = shift;

    # to deal with the Month mania.... Rajeev dude! :)
    my $show_year;
    my $show_month;
    my $show_day;
    my $show_rest;

    if ( $time_string =~ /(\d{4})-(\d{2})-(\d{2}) (.*)/ ) {
      $show_year = $1;
      $show_month = $2;
      $show_day = $3;
      $show_rest = $4;
    }

    my %h =  %NOC::labels_for_months;
    $show_month = $h{$show_month};

  ($show_year, $show_month, $show_day, $show_rest);

}

sub send_email {

  my (	 
    
	$created_or_updated,
	$last_insert_id,
	$short_description,
	$rt_ticket,
	$jira_ticket,
	$creator,
	$owner,
	$contact,
	$type,
	$criticality,
	$impacted_services,
	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	$status,
	$responsible_group,
	$root_cause,
	     
  ) = 	 @_ ;
 
  $ENV{PATH} = '/usr/lib';
  
  $creator =~ s{\@foobar.com}{}; # since we have @foobar.com appended to creator id...

  $creator = quotemeta( $creator );
  my $sendmail = "/usr/lib/sendmail -t -f $creator";
  
  $creator .= '@foobar.com';  #  rajeev wants to have @linkdin.com appended in the email

  $contact = $creator unless $contact;  # if no contact, let contact be creator

  # replace any https/http part anywhere in description with an anchor
  $description =~ s{(https?[^\s]*)}{<a href='$1'> $1 </a>}ixms ;

  $description =~ s/\n/\n<br>/g;
  $end_user_instruction =~ s/\n/\n<br>/g;
  $comments =~ s/\n/\n<br>/g if $comments;
  $root_cause =~ s/\n/\n<br>/g if $root_cause;

  # \\\\\\% -> %
  $short_description =~ s{\\+%}{%}g ;
  $description =~ s{\\+%}{%}g ;
  $end_user_instruction =~ s{\\+%}{%}g ;
  $comments =~ s{\\+%}{%}g if $comments ;
  $root_cause =~ s{\\+%}{%}g if $root_cause;
  
  $start_time =~ s/:$//;
  $detection_time =~ s/:$//;
  $end_time =~ s/:$//;

  $responsible_group ||= '';
  $root_cause ||= '';

  # dealing with "new" indicator
  my ( $show_start_year, $show_start_month, $show_start_day, $show_start_rest ) =  get_time_fragments( "$start_time" );

  my $time_string_for_compare_start_time = $1 if $start_time =~ /(.*) .*/;   # should be sth. like  2011-01-13
  my $time_string_for_compare_today_time =  NOC::get_today();  # shoud be sth. like 2011-01-13
  
  $created_or_updated = 'Closed' if $status =~ /closed/i;

  my $send_from = "Reply-to: $owner\n";
  my $send_to = "To: $contact\n";
  my $subject = "Subject: GCN $last_insert_id $created_or_updated - $type ($criticality): $short_description \n";
  my $content_type = "Content-Type: text/html\n\n"; 

  my $content ;

   	$content .= "<p><br />";
   	$content .= "<hr />";
   	$content .= "<h2> Production Operations Global Change Notice </h2>";
   	$content .= "<hr>";
   	$content .= "<table>";
        if ( $time_string_for_compare_start_time eq $time_string_for_compare_today_time ) {
   	  $content .= "<tr><td> <b>GCN#  </b>  </td><td>:  <a  href='${http_proto}://$server_name$view_script?id=$last_insert_id'>$last_insert_id</a> <i><b><font color='red'> (New) </font> </b></i>  </td></tr> ";
        }
        else {
   	  $content .= "<tr><td> <b>GCN#  </b>  </td><td>:  <a  href='${http_proto}://$server_name$view_script?id=$last_insert_id'>  $last_insert_id   </a>   </td></tr> ";
        }
#   	$content .= "<tr><td> <b>GCN#  </b>  </td><td>:  $last_insert_id ( <a href='${http_proto}://$server_name$view_script?id=$last_insert_id'> ${http_proto}://$server_name$view_script?id=$last_insert_id  </a>  ) </td></tr> ";
	$content .= "<tr><td> <b>Short description</b>  </td><td>: $short_description </td></tr> ";
	$content .= "<tr><td> <b>RT ticket</b>  </td><td>: $rt_ticket </td></tr> ";
	$content .= "<tr><td> <b>JIRA ticket</b>  </td><td>: $jira_ticket </td></tr> ";
	$content .= "<tr><td> <b>Creator</b>  </td><td>: $creator </td></tr> ";
	$content .= "<tr><td> <b>Owner Email</b>  </td><td>: $owner </td></tr> ";
	$content .= "<tr><td> <b>Contact Email</b>  </td><td>: $contact </td></tr> ";
	$content .= "<tr><td> <b>Outage type</b>  </td><td>: $type </td></tr> ";
	$content .= "<tr><td> <b>Criticality</b>  </td><td>: $criticality </td></tr> ";
	$content .= "<tr><td> <b>Status</b>  </td><td>: $status </td></tr> ";
	$content .= "<tr><td> <b>Impacted services</b>  </td><td>: $impacted_services </td></tr> \n ";
	$content .= "<tr><td> <b>Outage Start Time</b>  </td><td>: $start_day_of_week $start_time  </td></tr> \n ";
	$content .= "<tr><td> <b>Outage End Time</b>  </td><td>: $end_day_of_week $end_time </td></tr> \n ";
#	$content .= "<tr><td> <b>Outage Detection Time</b>  </td><td>: $end_day_of_week $end_time </td></tr> \n ";

   	$content .= "</table> \n";

   	$content .= "\n<br>";
   	$content .= "\n<br>";

        if ( $status eq 'Closed' ) {
          if ( $responsible_group ) {
	    $content .= "<b>Responsible Group:</b> $responsible_group\n<p>";
          }
          if ( $root_cause ) {
	    $content .= "<b>Root Cause:</b><p> $root_cause\n<p>";
          }
        }

   	$content .= "\n<br>";

	$content .= "<b>Problem Description and Updates:</b> \n<p>$description\n<p>";
	$content .= "<b>End user instruction:</b> \n<p>$end_user_instruction\n<p>";
#	$content .= "<b>Comments:</b> \n<p>$comments\n<p>";

	$content .= "\n\n<p>";


  open( MAIL, "|$sendmail ")  or die "cannot open $sendmail: $!\n";
  print MAIL $send_from;
  print MAIL $subject;
  print MAIL $send_to;
  print MAIL $content_type;
  print MAIL $content;
  close MAIL;

}


sub update_db {

  my (	 
    
	$gcn,
	$short_description,
	$rt_ticket,
	$jira_ticket,
	$creator,
	$owner,
	$contact,
	$type,
	$criticality,
	$impacted_services,
	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	$status,
	$responsible_group,
	$root_cause,
	     
  ) = 	 @_ ;
    
  # quotemeta if possible
  $short_description = quotemeta(  $short_description  );   
  $impacted_services = quotemeta( $impacted_services );
  $description = quotemeta( $description );
  $end_user_instruction = quotemeta( $end_user_instruction ) if $end_user_instruction;
  $comments = quotemeta( $comments ) if $comments;
  $root_cause = quotemeta( $root_cause ) if $root_cause;

  # \\\\\\% -> %
  $short_description =~ s{\\+%}{%}g ;
  $description =~ s{\\+%}{%}g ;
  $end_user_instruction =~ s{\\+%}{%}g ;
  $comments =~ s{\\+%}{%}g ;


  my $dbh = NOC::get_dbh();
  
  my $sql = qq[ 

		UPDATE outage 
		SET

                short_description = '$short_description',
                rt_ticket = '$rt_ticket',
                jira_ticket = '$jira_ticket',
                creator = '$creator',
                owner = '$owner',
                contact = '$contact'  ,
                type = '$type'  ,
                criticality = '$criticality'  ,
                impacted_services = '$impacted_services'  ,
                description = '$description'  ,
                end_user_instruction = '$end_user_instruction'  ,
                comments =  '$comments' ,
		start_day_of_week = '$start_day_of_week'  ,
		detection_day_of_week = '$detection_day_of_week'  ,
		end_day_of_week = '$end_day_of_week'  ,
                start_time =  '$start_time' ,
                detection_time =  '$detection_time' ,
                est_end_time =  '$end_time',
                status = '$status',
                responsible_group = '$responsible_group',
                root_cause = '$root_cause'

		WHERE id = $gcn
        
	];

   my $rc = $dbh->do( $sql ) or die "oops, unable to do $sql: $dbh->errstr\n";
   print "$rc rows were updated.<p>";
   
   audit_trail( $creator, "updated $gcn");  # also audit update action

   return $rc; 
 
#  my $last_insert_id = $dbh->{ q{mysql_insertid}};
#  print " last_insert_id: $last_insert_id";
#
#  return $last_insert_id;

}


sub insert_into_db {

  my (	 
    
	$short_description,
	$rt_ticket,
	$jira_ticket,
	$creator,
	$owner,
	$contact,
	$type,
	$criticality,
	$impacted_services,
	$description,
	$end_user_instruction,
	$comments,
	$start_day_of_week,
	$detection_day_of_week,
	$end_day_of_week,
	$start_time,
	$detection_time,
	$end_time,
	     
  ) = 	 @_ ;
    
  # quotemeta if possible
  $short_description = quotemeta(  $short_description  );   
  $impacted_services = quotemeta( $impacted_services );
  $description = quotemeta( $description );
  $end_user_instruction = quotemeta( $end_user_instruction );
  $comments = quotemeta( $comments ) if $comments;
  
  # \\\\\\% -> %
  $short_description =~ s{\\+%}{%}g ;
  $description =~ s{\\+%}{%}g ;
  $end_user_instruction =~ s{\\+%}{%}g ;
  $comments =~ s{\\+%}{%}g ;

  my $dbh = NOC::get_dbh();
  
  my $sql = qq[  INSERT INTO outage (

                short_description,
                rt_ticket,
                jira_ticket,
                creator,
                owner,
                contact,
                type,
                criticality,
                impacted_services,
                description,
                end_user_instruction,
                comments,
		start_day_of_week,
		detection_day_of_week,
		end_day_of_week,
                start_time,
                detection_time,
                est_end_time,
		status
        
	) 
	values( 
                '$short_description',
                '$rt_ticket',
                '$jira_ticket',
                '$creator',
                '$owner',
                '$contact',
                '$type',
                '$criticality',
                '$impacted_services',
                '$description',
                '$end_user_instruction',
                '$comments',
		'$start_day_of_week',
		'$detection_day_of_week',
		'$end_day_of_week',
                '$start_time',
                '$detection_time',
                '$end_time',
		'Pending'
        
	)  
	];

   $dbh->do( $sql );
 
  my $last_insert_id = $dbh->{ q{mysql_insertid}};
  print " last_insert_id: $last_insert_id";

  return $last_insert_id;

}

######################### for LDAP
sub display_login_form {

  my $gcn_number = shift;

  print <<FORM;

 <link rel="stylesheet" type="text/css" href="http://cinco.corp.foobar.com/cssfinal/layout.css"  />
 <link rel="stylesheet" type="text/css" href="http://cinco.corp.foobar.com/cssfinal/forms.css"  />

<body onload="document.login.username.focus();">

 <div>
 <h1>Welcome to GCN.  Login with your network username and password.</h1>

                <div id="error"></div>
                <form action="${http_proto}://${server_name}${this_script}"  method="post" class="foobar_form" id="login" name="login">
                        <input type="hidden" name="form_submitted" value="1">
                        <input type="hidden" name="gcn_number" value="$gcn_number">
                        <div><label>User Name: </label><input  type="text" name="username" id="username" /></div>
                        <div><label>Password: </label><input type="password" name="password" id="password" /></div>
                        <div><label>&nbsp;</label><input type="submit" name="submit" value="Login" id="submit" /></div>
                </form>

</div>

</body>


FORM

  exit;

}


sub find_cn_of_user {

  my $username = shift;

  my $bind_string =  "cn=Active Directory Monitor Pseudo-User,ou=Pseudo-Users,dc=foobar,dc=biz";
  my $bindPass = 'password';


  my $ldap = Net::LDAP->new( $ldapServer ) or die "$@";

  $ldap->bind($bind_string, password => $bindPass);

  my $mesg = $ldap->search (
#                        filter => "mailNickname=$username",
                        filter => "samaccountname=$username",
                        base => "ou=staff users,dc=foobar,dc=biz",
                        scope => 'sub',
                        attrs => 'cn');

  return if  $mesg->code();

  my @entries = $mesg->entries;

  foreach my $entry ( @entries ) {
    if ( $entry->get_value("departmentNumber") ==  $allowed_department_number_1  or  
	 $entry->get_value("departmentNumber") ==  $allowed_department_number_2  ) { 
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
  my $username = shift;

  my $bind_string =  "cn=$cn,ou=staff users,dc=foobar,dc=biz";
  my $bindPass = "$password";


  my $ldap = Net::LDAP->new( $ldapServer ) or die "$@";

  $ldap->bind($bind_string, password => $bindPass);

  my $mesg = $ldap->search (
#                        filter => "mailNickname=$username",
                        filter => "samaccountname=$username",
                        base => "ou=staff users,dc=foobar,dc=biz",
                        scope => 'sub',
                        attrs => 'cn');

  return if  $mesg->code();

  my @entries = $mesg->entries;

  foreach my $entry ( @entries ) {
    if ( $entry->get_value("departmentNumber") ==  $allowed_department_number_1  or  
	 $entry->get_value("departmentNumber") ==  $allowed_department_number_2  ) { 
      return $entry->get_value("CN");
    }
    else {
      return;
    }
  }

}

sub is_user_with_delete_priv {

  my $username = shift;

  my @allowed_users = get_admin_users();

  grep { $_ eq $username  } @allowed_users;

}

sub get_admin_users {

  my $dbh = NOC::get_dbh();

  my $stmt = qq[

        SELECT username FROM admin

  ];

  my $sth = $dbh->prepare( $stmt ) or die "stmt error: " . $dbh->errstr;
  $sth->execute();

  my $ref = $sth->fetchall_arrayref;
  my @admins;

  foreach my $row ( @{$ref} ) {
    push @admins, @$row;
  }

  @admins;

}


sub delete_gcns {

  my $gcns_to_delete = param("gcns_to_delete");
  $gcns_to_delete =~ s/\s+//;
  $gcns_to_delete =~ s/\,+/\,/;
  $gcns_to_delete =~ s/\,$//;

  my $dbh = NOC::get_dbh();

  # simple do
  # delete from testme where id in (1,2);
  my $stmt = qq[

    DELETE FROM outage where id in ( $gcns_to_delete )

  ];

  $dbh->do( $stmt ) or die "failed to delete GCN(s): $gcns_to_delete" . $dbh->errstr;

  print p("The following GCN(s) have been deleted");

  print p("$gcns_to_delete");

  my $username = param("username");

  audit_trail( $username, "deleted $gcns_to_delete");
  
}

sub audit_trail {

  my $who = shift;
  my $what = shift;

  my $dbh = NOC::get_dbh();

  my $stmt = qq[
  
    INSERT INTO audit(`who`, `what`)
    values('$who', '$what')

  ];
  
  $dbh->do( $stmt ) or warn "warning: cannot audit $who $what" . $dbh->errstr;


}




#################### main() 


my $gcn_number = param("gcn_number") || '';

display_login_form( $gcn_number ) unless  param("form_submitted");

my $username = param("username");
my $password = param("password");


unless ( find_cn_of_user( $username ) ) {
  print "you must be kidding";
  exit;
}

my $cn =  find_cn_of_user( $username );
unless ( password_ok( $cn , $password, $username ) ) {
  print "Oops, you provided a wrong password, go back and try again.";
  exit;
}

# all clear... go

=pod

print "<p> ENVs <p>";
while( my ($k, $v) = each %ENV ) {
  print "$k => $v<p>";
}

print "<p> Params <p>";
for my $name ( param() ) {
  print "$name => " , param($name), "<p>" ;
}

=cut




if ( param("gcn_number") ) {

  update_gcn( param("gcn_number")  );

}


if ( param("submit") and  param("submit") eq "Submit" ) {

#  print "in Submit process_form";

  process_form();

}
elsif ( param("submit") and  param("submit") eq "Update" ) {

#  print "in Update process_form";

  update_process_form();

}
elsif ( param("submit") and  param("submit") eq "Delete" ) {

  delete_gcns();

}
else {

#  print "<center>";

  print h1( " <center> GCN(Outage Board) Fill Out Form </center>" );

  display_gcn_number_search();

  if ( is_user_with_delete_priv( $username ) ) {
    # username, e.g, lwang,  has the delete priv
    #print "you are in<p />";
    display_delete_form();

  }
  else {
    # username does not have  the delete priv,  nothing to display here
    #print "you have NO delete priv<p />";

  }

  display_form();

#  print "</center>";


}


NOC::show_footer();


print end_html();

exit;



