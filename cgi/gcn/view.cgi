#!/usr/local/perl/bin/perl -wT
#!/bin/perl -wT
use strict;
use CGI qw(:standard);
use DBI;

use lib '.';
use NOC;

my $http_proto = $NOC::http_proto;

my $http_host = $ENV{HTTP_HOST};


my $id = param("id");

print header();

print start_html(
                -title => "GCN Dashboard",
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



if ( param("gcn_number") ) {

  view_detail( param("gcn_number")  );

}


sub get_time_now {

  use POSIX qw(strftime);
  strftime "%Y-%m-%d", localtime;
}


sub display_gcn_number_search {

  print start_form();

  print "GCN#: ", textfield( -name => 'gcn_number', -id => 'gcn_number', -size => '10' ) ;
  print submit( -name => 'submit', -value => 'View Detail' );
#  print reset( -name => 'cancel', -value => 'Reset' );

  print end_form();

}


sub display_advanced_search {

  print start_form( -id => 'advanced_search', -name => 'advanced_search' );

  print "<fieldset>";
  print "<legend> Advanced Search </legend>";

  my @search_fields = qw(
    short_description
    criticality
    rt_ticket
    jira_ticket
    type
    impacted_services
    description
    end_user_instruction
    comments
    creator
    owner
    contact
    status 

  );

  my @search_fields_shown = qw(
    Short_Description
    Criticality
    RT_ticket
    JIRA_ticket
    Type
    Impacted_services
    Description
    End_user_instruction
    Comments
    Creator
    Owner
    Contact
    Status 

  );

  my %labels_for_search_fields;
  @labels_for_search_fields{@search_fields} = @search_fields_shown;

  print br();
  print b('Field to search:');
  print popup_menu(
    -name => 'search_field',
    -id => 'search_field',
    -values => \@search_fields,
#    -default => $default_month,
    -labels => \%labels_for_search_fields,
  );


  print textfield( -name => 'search_field_text', -id => 'search_field_text', -size => '63' );

  print " --or--  ";

#  print textfield( -name => 'adv_search_field_text', -id => 'adv_search_field_text', -size => '50', -default => 'search in any of the dropdown fields '  );


  print br();
  print br();

#  $ENV{PATH} = '/bin';
#  chomp( my $now = `date +%Y-%m-%d` );

  my $in_the_beginning = '2010-06-29';
  my $now = get_time_now();


  print <<ADVS_TABLE;

<table>
<tr><td> Search these words: </td><td>  <input type="text" size='80' name="adv_search_field_text" id="adv_search_field_text" > </td></tr> 

<tr><td> Start Date  between:  </td><td><input type="text" value="$in_the_beginning" readonly="readonly"  name="theDate0S" id="theDate0S">   <input type="button" value="Cal" onclick="displayCalendar(document.getElementById('advanced_search').theDate0S ,'yyyy-mm-dd',this)">  and  <input type="text" value="$now" readonly="readonly"  name="theDate0E" id="theDate0E">   <input type="button" value="Cal" onclick="displayCalendar(document.getElementById('advanced_search').theDate0E ,'yyyy-mm-dd',this)">    </td> </tr>

</table>

ADVS_TABLE

#  print "GCN#: ", textfield( -name => 'gcn_number', -id => 'gcn_number', -size => '10' ) ;
  print br();
  print submit( -name => 'submit', -value => 'Search' );
#  print reset( -name => 'cancel', -value => 'Reset' );
  print "</fieldset>";

  print end_form();

  print br();
}


sub view_summary {

  my $stmt = shift;

  # output to the browser 
  
  print "<p>";
#  print "<body bgcolor='#235899'>";
#  print "<body bgcolor='#00CC00'>";
  print "<body >";
  print img(  { -src => '/lwang/images/NOC.jpg', -align => 'left', -width => '250', -height => '100'  } ) ;
#  print img(  { -src => '/lwang/images/Outage-Desc.jpg', -align => 'right', -width => '200', -height => '100'   } ) ;
  print img(  { -src => '/lwang/images/Outage-Desc.jpg', -align => 'right' } );


#  print hr();
  print br();
  print br();
  print br();
  print br();
  print br();

  print "<center>";
  print " <div id='gcn_dashboard_title'> <h1>  Global Change Notice (GCN) Dashboard  </h1> </div> ";

#  print img( { -src => '/lwang/images/topBar1.png', -align => 'center'  } );
#  print img( { -src => '/lwang/images/topBar1.png', -style => 'position:center,overflow; width: 2500; height: 20      '  } );

#  print img( { -align => 'left',  -height => '20', -width => '1500',  -src => '/lwang/images/topBar1.png' } );
  print hr();
  print br();

  display_gcn_number_search();

  print br();


#  print hr( { -width => '1000' , align => 'center' } );

  print "<table border='1'>\n";

  print "<tr>";
  print "<th> GCN# </th>";
  print "<th> Short Description  </th>";
#  print "<th> RT Ticket # </th>";
#  print "<th> JIRA Ticket # </th>";
  print "<th> JIRA# </th>";
  print "<th> Outage Start Time  </th>";
  print "<th> Outage End Time  </th>";
  print "<th> Outage Type </th>";
  print "<th> Criticality </th>";
  print "<th> Status </th>";
#  print "<th>  Details &nbsp; </th>";
  print "<th>  Update </th>";
  print "</tr>";



  my $dbh = NOC::get_dbh();
  
  # prepare and execute query

  my $query = $stmt;

#  my $query = qq[ 
#		SELECT id, short_description, rt_ticket, type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time  
#		FROM outage 
#		WHERE status = 'pending'
#		ORDER BY type DESC, criticality, start_time DESC
#		];

  my $sth = $dbh->prepare($query);
  $sth->execute();
  
  # assign fields to variables
  my ($id, $short_description, $rt_ticket, $jira_ticket,  $type, $criticality, $start_day_of_week, $end_day_of_week, $start_time, $est_end_time, $status );
  
  $sth->bind_columns(\$id, \$short_description, \$rt_ticket, \$jira_ticket, \$type, \$criticality, \$start_day_of_week, \$end_day_of_week, \$start_time, \$est_end_time , \$status);
  
  # http://www.computerhope.com/htmcolor.htm
  while($sth->fetch()) {
    if ( $type =~ /unplanned/i &&  $criticality =~ /major/i ) {
      print "<tr bgcolor='red'>";
    }
    elsif (  $type =~ /unplanned/i &&  $criticality =~ /moderate/i  )  {
      print "<tr bgcolor='#F88017'>";   #  dark orange 
    }
    elsif (  $type =~ /unplanned/i &&  $criticality =~ /minor/i  )  {
      print "<tr bgcolor='#41627E'>";   # sky blue 
    }
    else {
      print "<tr >";
    }

    # to deal with the Month mania.... Rajeev dude! :)



    my ( $show_start_year, $show_start_month, $show_start_day, $show_start_rest ) =  get_time_fragments( "$start_time" );
    my ( $show_end_year, $show_end_month, $show_end_day, $show_end_rest ) =  get_time_fragments( "$est_end_time" );


    my $time_string_for_compare_start_time = $1 if $start_time =~ /(.*) .*/;   # should be sth. like  2011-01-13
    my $time_string_for_compare_today_time =  NOC::get_today();  # shoud be sth. like 2011-01-13


    my $create_script_name = $ENV{SCRIPT_NAME};  # /cgi-bin/lwang/test/view.cgi
    $create_script_name =~ s/view/create/;

    # \\\\\\% -> %
    $short_description =~ s{\\+%}{%}g ;

    $rt_ticket ||= "";
    $jira_ticket ||= "";
#    print "<td> <a href='${http_proto}://$http_host$create_script_name?gcn_number=$id'> $id </a> </td>";
#    print "<td> <a href='?id=$id'> $id </a> </td>";
    if ( $time_string_for_compare_start_time eq $time_string_for_compare_today_time ) {
      print "<td>  <a href='?id=$id'> $id </a> <img src='/lwang/images/New_icons_23.gif' alt='NEW' >  </td>";
    }
    else {
      print "<td> <a href='?id=$id'> $id </a> </td>";
    }


    print "<td>$short_description</td>";

    # rajeev wants to squeeze both RT and JIRA tickets into one column shown. it's "either o" case
    if ( $rt_ticket ) {
      print "<td> <a href=' https://siteops-rt.corp.foobar.com/Ticket/Display.html?id=$rt_ticket '  target='_blank' > $rt_ticket </td>";
    }
    elsif ( $jira_ticket ) {
#      print "<td> <a href=' https://iwww.corp.foobar.com/ist/jira/browse/$jira_ticket '  target='_blank' > $jira_ticket </td>";
      print "<td> <a href=' https://jira01.corp.foobar.com:8443/browse/$jira_ticket '  target='_blank' > $jira_ticket </td>";
    }
    else {
      print "<td>   </td>";
    }

#    print "<td>$start_day_of_week $start_time</td>";
#    print "<td>$end_day_of_week $est_end_time</td>";
    print "<td>$start_day_of_week $show_start_day $show_start_month $show_start_year $show_start_rest  </td>";
    print "<td>$end_day_of_week $show_end_day $show_end_month $show_end_year $show_end_rest  </td>";
    print "<td>$type</td>";
    print "<td>$criticality</td>";
    print "<td>$status</td>";
#    print "<td> <a href='?id=$id'> details  </a> </td>";
#    print "<td> <a href='?id=$id'> <img src='/lwang/images/play_button_blue.jpg' width='30', height='30' >  </a> </td>";
    print "<td> <a href='${http_proto}://$http_host$create_script_name?gcn_number=$id'> <img src='/lwang/images/play_button_blue.jpg' width='30', height='30' >  </a> </td>";
    print "</tr>";
  }
  
  
  print "</table>\n";
  print "</center>";
  print "</body>\n";
  print "</html>\n";
  
  $sth->finish();
  
  # disconnect from database
  $dbh->disconnect;

  print p();
#  print img( { -align => 'left', -height => '20', -width => '1500',  -src => '/lwang/images/bottombar.png' } );
  print hr();

  print br();

#  print img( { -src => '/lwang/images/bottombar.png', -style => 'position:center,overflow; width: 1500; height: 20      '  } );
#  print img( { -src => '/lwang/images/bottombar.png',  -align => 'center'  } );

  display_advanced_search();

  NOC::show_footer();

  exit;
}


sub view_detail {

  my $id = shift;

  my $dbh = NOC::get_dbh();
  
  # prepare and execute query
  my $query = qq[ 
		SELECT 
		id, short_description, criticality,  rt_ticket, jira_ticket,  type,   impacted_services,  description,   end_user_instruction ,  comments , creator, owner  , contact , justnow , created , 
		updated, start_time, est_end_time, start_day_of_week, end_day_of_week, status

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
  my $est_end_time;
  my $start_day_of_week;
  my $end_day_of_week;
  my $status;

  my $jk;
  

  # mysql> select * from outage;
  #  outdated!!!!!!  id | short_description              | criticality | rt_ticket | type | impacted_services | description | end_user_instruction | comments | owner  | contact | justnow | created             | updated  

  $sth->bind_columns(\$id, \$short_description, \$criticality, \$rt_ticket,  \$jira_ticket, \$type, \$impacted_services, \$description, \$end_user_instruction, \$comments, \$creator,  \$owner, \$contact, \$justnow, \$created, \$updated, \$start_time, \$est_end_time , \$start_day_of_week, \$end_day_of_week, \$status );
  
  # output to the browser 
  


  my $record_exists;
  while ( $sth->fetch() ) {


    my ( $show_start_year, $show_start_month, $show_start_day, $show_start_rest ) =  get_time_fragments( "$start_time" );
    my ( $show_end_year, $show_end_month, $show_end_day, $show_end_rest ) =  get_time_fragments( "$est_end_time" );

    $description =~ s/\n/\n<br>/g		if $description;
    $end_user_instruction =~ s/\n/\n<br>/g	if $end_user_instruction;
    $comments =~ s/\n/\n<br>/g			if $comments;

    # \\\\\\% -> %
    $short_description =~ s{\\+%}{%}g ;
    $description =~ s{\\+%}{%}g ;
    $end_user_instruction =~ s{\\+%}{%}g ;
    $comments =~ s{\\+%}{%}g ;

    $rt_ticket ||= '';
    $jira_ticket ||= '';
    $impacted_services ||= '';
    $description ||= '';
    $end_user_instruction ||= '';
    $comments ||= '';
    $creator ||= '';
 
    print "<p>\n";
    print "details for id $id <p>";
    print "<table border='2' >\n";
    print "<tr>";
    print "<th align='right'> Field  </th>";
    print "<th> Value  </th>";
    print "</tr>";
  
    print "<tr><th align='right'> id </th> <td> $id </td> <p> </tr>";
    print "<tr><th align='right'> short description  </th> <td> $short_description </td> <p> </tr>";
    print "<tr><th align='right'> RT ticket #  </th> <td> $rt_ticket </td> <p> </tr>";
    print "<tr><th align='right'> JIRA ticket #  </th> <td> $jira_ticket </td> <p> </tr>";
    print "<tr><th align='right'> Outage Type </th> <td> $type </td> <p> </tr>";
    print "<tr><th align='right'>  Creator   </th> <td> $creator </td> <p> </tr>";
    print "<tr><th align='right'>  Owner  </th> <td> $owner </td> <p> </tr>";
    print "<tr><th align='right'>  Contact  </th> <td> $contact </td> <p> </tr>";
    print "<tr><th align='right'>  Start Time  </th> <td>  $start_day_of_week $show_start_day $show_start_month $show_start_year $show_start_rest   </td> <p> </tr>";
    print "<tr><th align='right'>  End Time  </th> <td>   $end_day_of_week $show_end_day $show_end_month $show_end_year $show_end_rest  </td> <p> </tr>";
    print "<tr><th align='right'>  Impacted services  </th> <td> $impacted_services </td> <p> </tr>";

=pod
    if ( $criticality =~ /major/i ) {
      print "<tr bgcolor='red'><td>  Criticality  </td> <td> $criticality </td> <p> </tr>";
    }
    else {
      print "<tr bgcolor='#66EE00'> <td>  Criticality  </td> <td> $criticality </td> <p> </tr>";
    }
=cut

    print "<tr><th align='right'>  Criticality  </th> <td> $criticality </td> <p> </tr>";
    print "<tr><th align='right'>  Status  </th> <td> $status </td> <p> </tr>";

    # replace any https/http part anywhere in description with an anchor
    $description =~ s{(https?[^\s]*)}{<a href='$1' target='_blank'> $1 </a>}ixms ;
    
    print "<tr><th align='right'>  Description  </th> <td> $description </td> <p> </tr>";
    print "<tr><th align='right'>  End User Instruction  </th> <td> $end_user_instruction </td> <p> </tr>";
    print "<tr><th align='right'>  Comments  </th> <td> $comments </td> <p> </tr>";
#    print "<tr><th align='right'>  Updated  </th> <td> $updated </td> <p> </tr>";

    $record_exists++;
  }

 
  print "</table>\n";

  unless ( $record_exists  ) {

    print h3("Oops,  I did not find the GCN# you  provided. Are you sure it's valid?");

  }

  print "</body>\n";

  print p();
  print " <a href='?'> Go to dashboard </a> </td>";

  print "</html>\n";
  
  $sth->finish();
  
  # disconnect from database
  $dbh->disconnect;

  exit;
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



# 
view_detail( $id ) if $id;


# we are in "Advanced Search" fieldset
if ( param("submit") and param("submit") eq "Search" ) {

  my $theDate0S = param("theDate0S");
  my $theDate0E = param("theDate0E");

  if ( param("adv_search_field_text") ) {

    my $any =  param("adv_search_field_text");

    my $stmt = qq[

	SELECT   id, short_description, rt_ticket,  jira_ticket,  type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time, status
	FROM outage 
	WHERE MATCH(`short_description`,`criticality`,`rt_ticket`, `jira_ticket`, `type`,`impacted_services`,`description`,`end_user_instruction`,`comments`,`creator`,`owner`,`contact`,`status`) AGAINST ('$any' IN BOOLEAN MODE)
	AND start_time between  '$theDate0S' and '$theDate0E 23:59:59'
	ORDER BY type DESC,  Field(criticality,'Major','Moderate','Minor') , start_time DESC

    ];

    if ( param("ds3_daily_report") ) {

      my $today = NOC::get_today();
      my $yesterday = NOC::get_yesterday();

      $stmt = qq[

	SELECT   id, short_description, rt_ticket,  jira_ticket,  type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time, status
	FROM outage 
	WHERE MATCH(`short_description`,`criticality`,`rt_ticket`, `jira_ticket`, `type`,`impacted_services`,`description`,`end_user_instruction`,`comments`,`creator`,`owner`,`contact`,`status`) AGAINST ('$any' IN BOOLEAN MODE)
	AND start_time between  '$yesterday' and '$today 23:59:59'
	ORDER BY type DESC,  Field(criticality,'Major','Moderate','Minor') , start_time DESC

      ];


    }

    view_summary( $stmt );


  } 
  else {
    # for single field search

    my $search_field = param("search_field");
    my $search_field_text = param("search_field_text");


#    print "search_field :  $search_field<p>";
#    print "search_field_text: $search_field_text<p>";

    
    my $stmt = qq[
		SELECT id, short_description, rt_ticket, jira_ticket, type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time , status 
		FROM outage 
		WHERE $search_field REGEXP  '$search_field_text'
		AND start_time between  '$theDate0S' and '$theDate0E 23:59:59'
		ORDER BY type DESC,  Field(criticality,'Major','Moderate','Minor') ,  start_time DESC
	];

    view_summary( $stmt );

  } 


  exit;

}


# no $id provided, view_summary

my $stmt = qq[
		SELECT id, short_description, rt_ticket, jira_ticket, type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time , status 
		FROM outage 
		WHERE status = 'pending'
		ORDER BY type DESC, Field(criticality,'Major','Moderate','Minor'), start_time DESC
	];

view_summary( $stmt) ;



print end_html();


exit;
