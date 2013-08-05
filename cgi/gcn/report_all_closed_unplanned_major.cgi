#!/usr/local/perl/bin/perl -wT
#!/bin/perl -wT
use strict;
use CGI qw(:standard);
use DBI;

use Time::Local;

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


sub display_customized_query {

  print start_form( -id => 'advanced_search', -name => 'advanced_search' );

  print "<fieldset>";
  print "<legend> Customized Query </legend>";

  my $in_the_beginning = '2010-06-29';
  my $now = get_time_now();


#  print checkbox(
#    -name => 'total_unplanned',
#    -value => 'total_unplanned',
#    -selected => 1,
#    -label => 'Total Unplanned',
#  );


  print <<ADVS_TABLE;

<table>

<tr><td> From:  </td><td><input type="text" value="$now" readonly="readonly"  name="theDate0S" id="theDate0S">   </td><td> <input type="button" value="Cal" onclick="displayCalendar(document.getElementById('advanced_search').theDate0S ,'yyyy-mm-dd',this)">   </td></tr>

<tr><td> To:  </td><td> <input type="text" value="$now" readonly="readonly"  name="theDate0E" id="theDate0E">   </td><td> <input type="button" value="Cal" onclick="displayCalendar(document.getElementById('advanced_search').theDate0E ,'yyyy-mm-dd',this)">    </td> </tr>

</table>

ADVS_TABLE

  print br();
  print submit( -name => 'submit', -value => 'Submit' );
  print "</fieldset>";

  print end_form();

  print br();
}


sub view_count {

  my $gcns_hashref = shift;
  my $gcns_arrayref = shift;

  my %gcns = %$gcns_hashref;

  my $content;
#--------------
  my $count_unplanned_major = 0;
  my $count_unplanned_moderate = 0;
  my $count_unplanned_minor = 0;

  my $count_planned_major = 0;
  my $count_planned_moderate = 0;
  my $count_planned_minor = 0;

  for my $id ( @{$gcns_arrayref}  ) {
    
    my $short_description = $gcns{$id}->{'short_description'};
    my $type = $gcns{$id}->{'type'};
    my $criticality = $gcns{$id}->{'criticality'};

    my $start_day_of_week = $gcns{$id}->{'start_day_of_week'};
    my $end_day_of_week = $gcns{$id}->{'end_day_of_week'};
    my $start_time = $gcns{$id}->{'start_time'};
    my $est_end_time = $gcns{$id}->{'est_end_time'};

    if ( $type eq 'Unplanned' ) {
      if ( $criticality eq 'Major' ) {
        $count_unplanned_major++;    
      } elsif ( $criticality eq 'Moderate') {
        $count_unplanned_moderate++;
      } elsif ( $criticality eq 'Minor') {
        $count_unplanned_minor++;
      }
    }
    elsif ( $type eq 'Planned' )  {
      if ( $criticality eq 'Major' ) {
        $count_planned_major++;    
      } elsif ( $criticality eq 'Moderate') {
        $count_planned_moderate++;
      } elsif ( $criticality eq 'Minor') {
        $count_planned_minor++;
      }
    }
  }

  $content .=  "# of unplanned major:  $count_unplanned_major<br />";
  $content .=  "# of unplanned moderate:  $count_unplanned_moderate<br />";
  $content .=  "# of unplanned minor:  $count_unplanned_minor<br />";
  $content .= '<p>';
  $content .=  "# of planned major:  $count_planned_major<br />";
  $content .=  "# of planned moderate:  $count_planned_moderate<br />";
  $content .=  "# of planned minor:  $count_planned_minor<br />";
#--------------

  print $content;

}


sub get_stmt_result {

  my $stmt = shift;

  my $dbh = NOC::get_dbh();

  my $query = $stmt;

  my $sth = $dbh->prepare($query);
  $sth->execute();

  my $rs = $sth->fetchall_arrayref();

  return $rs->[0]->[0];

}


sub show_customized_query_results {

  my $theDate0S = shift;
  my $theDate0E = shift;

  my $stmt_total_unplanned = qq[
		SELECT count(*) 
		FROM outage 
		WHERE type = 'unplanned'
		AND start_time >=  '$theDate0S' and est_end_time < '$theDate0E 23:59:59'
	];

  my $stmt_total_unplanned_major = qq[
		SELECT count(*) 
		FROM outage 
		WHERE type = 'unplanned' and criticality = 'major'
		AND start_time >=  '$theDate0S' and est_end_time < '$theDate0E 23:59:59'
	];


  my $total_unplanned = get_stmt_result( $stmt_total_unplanned );
  my $total_unplanned_major = get_stmt_result( $stmt_total_unplanned_major );


  print "<p>";
  print "<body >";
  print img(  { -src => '/lwang/images/NOC.jpg', -align => 'left', -width => '250', -height => '100'  } ) ;

  print br();
  print br();
  print br();
  print br();
  print br();

  print "<center>";
  print " <div id='gcn_dashboard_title'> <h1>  GCN Report  </h1> </div> ";

  print hr();
  print br();
  print br();
  print br();

=pod
  my $dbh = NOC::get_dbh();

  my $query = $stmt;

  my $sth = $dbh->prepare($query);
  $sth->execute();

  my $rs = $sth->fetchall_arrayref();

  my $count = $rs->[0]->[0];
=cut


  print "From $theDate0S to $theDate0E<p>";
  print "Total count of unplanned: $total_unplanned<p>";
  print "Total count of unplanned major: $total_unplanned_major<p>";
 
}

sub view_summary {

  my $stmt = shift;

  # output to the browser 
  
  print "<p>";
  print "<body >";
  print img(  { -src => '/lwang/images/NOC.jpg', -align => 'left', -width => '250', -height => '100'  } ) ;

  print br();
  print br();
  print br();
  print br();
  print br();

  print "<center>";
  print " <div id='gcn_dashboard_title'> <h1>  GCN Report  </h1> </div> ";

  print hr();
  print br();

#  display_gcn_number_search();

  print br();

#  my ($gcns_hashref, $gcns_arrayref )  = get_gcns();
#  view_count( $gcns_hashref, $gcns_arrayref ) ;
#  print hr();

  print br();


######### add flavor for paging
  my $limit = param('limit');
  $limit = 0 if ! $limit;

  my $results_per_page = param("results_per_page") || 10;


#########


  my $dbh = NOC::get_dbh();

  my $query = $stmt;

  my $sth = $dbh->prepare($query);
  $sth->execute();
  

  use POSIX;
  my $results = $sth->rows;
  my $pages_required = ceil($results / $results_per_page);


  my $sql_limited = qq[                
		SELECT id,  short_description, type, criticality,  start_day_of_week, end_day_of_week, detection_day_of_week, start_time, est_end_time, detection_time, status , responsible_group, root_cause
                FROM outage
                WHERE status = 'closed' and type = 'unplanned' and criticality = 'major' and  responsible_group is not null and root_cause is not null
                ORDER BY type DESC, Field(criticality,'Major','Moderate','Minor'), start_time DESC
		LIMIT $limit, $results_per_page
        ];


  my $sth_limited = $dbh->prepare($sql_limited);
  $sth_limited->execute() or die "cannot execute...";

  # assign fields to variables
  my ($id, $short_description, $rt_ticket, $jira_ticket,  $type, $criticality, $start_day_of_week, $end_day_of_week, $detection_day_of_week, $start_time, $est_end_time, $detection_time, $status, $responsible_group, $root_cause );
  
  $sth_limited->bind_columns(\$id,  \$short_description, \$type, \$criticality,  \$start_day_of_week, \$end_day_of_week, \$detection_day_of_week, \$start_time, \$est_end_time, \$detection_time, \$status, \$responsible_group, \$root_cause);


  

  print "<table border='1'>\n";
  print "<caption> All <span style='text-decoration: underline;'>  Closed Unplanned Major </span> GCNs with non-null Root Cause and Responsible Group ( total: $results ) </caption>";

  print "<tr>";
  print "<th> GCN# </th>";
  print "<th> Short Description  </th>";
  print "<th> Responsible Group </th>";
  print "<th> Root Cause </th>";
  print "<th> Start Time </th>";
  print "<th> Detection Time </th>";
  print "<th> End Time </th>";
  print "<th> Resolution Time </th>";
  print "<th> Detection Time </th>";
  print "</tr>";


 
  # http://www.computerhope.com/htmcolor.htm
  while($sth_limited->fetch()) {


    my ( $show_start_year, $show_start_month, $show_start_day, $show_start_rest ) =  get_time_fragments( "$start_time" );
    my ( $show_detection_year, $show_detection_month, $show_detection_day, $show_detection_rest ) =  get_time_fragments( "$detection_time" );
    my ( $show_end_year, $show_end_month, $show_end_day, $show_end_rest ) =  get_time_fragments( "$est_end_time" );


    my $duration_resolution_time = get_time_diff(  $start_time, $est_end_time );
    my $duration_detection_time = get_time_diff(  $start_time, $detection_time );

    print "<td><a href='?id=$id'> $id </a></td>";
    print "<td>$short_description</td>";
    print "<td>$responsible_group</td>";
    print "<td>$root_cause </td>";
    print "<td>$start_day_of_week $show_start_day $show_start_month $show_start_year $show_start_rest  </td>";
    print "<td>$detection_day_of_week $show_detection_day $show_detection_month $show_detection_year $show_detection_rest  </td>";
    print "<td>$end_day_of_week $show_end_day $show_end_month $show_end_year $show_end_rest  </td>";
    print "<td> $duration_resolution_time </td>";
    print "<td> $duration_detection_time </td>";
    print "</tr>";
  }
  
=pod

  my ($all_closed_unplanned_major_gcns_hash_ref, $all_closed_unplanned_major_gcns_array_ref) = get_all_closed_unplanned_major_gcns();
  my %all_closed_unplanned_major_gcns = %$all_closed_unplanned_major_gcns_hash_ref;
  my @all_closed_unplanned_major_gcns_array = @$all_closed_unplanned_major_gcns_array_ref;

  print sort keys  %all_closed_unplanned_major_gcns;
  print "<hr>";
  print "@all_closed_unplanned_major_gcns_array\n";
  print "<hr>";

  while( my @chunk = splice @all_closed_unplanned_major_gcns_array, 0, 5 ) {
    print "@chunk";
    print "<hr>";
  }

=cut

  print "</table>\n";
  print "</center>";


#print "results: $results <p>";
#print "pages_required: $pages_required <p>";

print p();


for (my $i = 0; $i <= $pages_required -1; $i++) {
  if ($i == 0) {
      if ($limit != 0) {
        if ( $results_per_page ) {
          print "<a href=\"?limit=0&results_per_page=$results_per_page\">";
        }
        else {
          print "<a href=\"?limit=0\">";
        } 
        print $i + 1;
        print "</a>";
      }
      else {print $i + 1;}
  }
  
  if ($i > 0) {
      if ($limit != ($i * $results_per_page)) {
       
        print ' | <a href="?limit=';
        print ($i * $results_per_page);

        if ( $results_per_page ) { 
          print "&results_per_page=$results_per_page";
        }
 
        print '">';
        print $i + 1, "</a>";
      }
      else {print " | ", $i + 1;}
  }
}



  print "</body>\n";
  print "</html>\n";
  
  $sth->finish();
  
  # disconnect from database
  $dbh->disconnect;

  print p();

  display_customized_query();

  print br();

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
    print "<th> Field  </th>";
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



sub get_time_diff {

  my $start_time_string = shift;
  my $end_time_string = shift;

  my ($year_1, $month_1, $day_1, $hour_1, $min_1, $sec_1) = get_time_list( $start_time_string );
  my ($year_2, $month_2, $day_2, $hour_2, $min_2, $sec_2) = get_time_list( $end_time_string );

  $month_1--;
  $month_2--;

  my $time_1;
  my $time_2;

  if ( $day_1 == 0 or $day_2 == 0 ) {
    'NA';
  }
  else {

    $time_1 = timelocal($sec_1, $min_1, $hour_1, $day_1, $month_1, $year_1);
    $time_2 = timelocal($sec_2, $min_2, $hour_2, $day_2, $month_2, $year_2);
 
    my $difference = $time_2 - $time_1;
 
    my $seconds    =  $difference % 60;
     $difference = ($difference - $seconds) / 60;
    my $minutes    =  $difference % 60;
     $difference = ($difference - $minutes) / 60;
    my $hours      =  $difference % 24;
     $difference = ($difference - $hours)   / 24;
    my $days       =  $difference % 7;
    my $weeks      = ($difference - $days)    /  7;

    if ( $days == 0 ) {
      "$hours: $minutes: $seconds";
    } 
    else {
      "$days days, $hours: $minutes: $seconds";
    }

  }

}

sub get_time_list {

  my $time_string = shift;

    my $show_year;
    my $show_month;
    my $show_day;
    my $show_hour;
    my $show_min;
    my $show_sec;

    if ( $time_string =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/ ) {
      $show_year = $1;
      $show_month = $2;
      $show_day = $3;
      $show_hour = $4;
      $show_min = $5;
      $show_sec = $6;
    }

  ($show_year, $show_month, $show_day, $show_hour, $show_min, $show_sec);

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


sub seven_days_ago
{

  my $epoch =$^T;

  $epoch -= (60*60*24*7);  # minus 7 days
  my $day = strftime "%Y-%m-%d", localtime($epoch);

  $day;

}


sub get_gcns {

  # start and end date, format: YYYY-MM-DD
  my ($start, $end) = @_;

  my $this_day = $end ? $end : strftime "%Y-%m-%d", localtime(time);  # this_day is a misnomer, it's whatever end date provided, if any, otherwise, it's today's date
  my $seven_days_ago = $start ? $start : seven_days_ago();      # seven_days_ago is a misnomer, it's whatever start date provided, if any, otherwise, it's seven days ago

  my %gcns;  
  my @gcns_array;

  my $dbh = NOC::get_dbh();

  my $stmt = qq[
	SELECT id, short_description, rt_ticket, jira_ticket,  type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time, status, creator 
 	FROM outage
	WHERE
		start_time >= '$seven_days_ago' and start_time <= '$this_day 23:59:59'
	ORDER BY type DESC, Field(criticality, 'Major', 'Moderate', 'Minor'), start_time DESC

  ];

  my $sth = $dbh->prepare($stmt) or die "stmt error: " . $dbh->errstr;
  $sth->execute();


  

  # assign fields to variables
  my ($id, $short_description, $rt_ticket, $jira_ticket,  $type, $criticality, $start_day_of_week, $end_day_of_week, $start_time, $est_end_time, $status, $creator );
  
  $sth->bind_columns(\$id, \$short_description, \$rt_ticket, \$jira_ticket, \$type, \$criticality, \$start_day_of_week, \$end_day_of_week, \$start_time, \$est_end_time, \$status, \$creator );
  

  my $record_exists;
  while ( $sth->fetch() ) {

    #print "$id\n";
    push @gcns_array, $id;
      $gcns{$id} = {
                short_description => $short_description, 
                rt_ticket => $rt_ticket, 
                jira_ticket => $jira_ticket,  
                type => $type, 
                criticality => $criticality, 
                start_day_of_week => $start_day_of_week, 
                end_day_of_week => $end_day_of_week, 
                start_time => $start_time, 
                est_end_time => $est_end_time ,
                status => $status, 
                creator => $creator, 
        };  

    $record_exists++;

  }

  unless ( $record_exists ) {

    print "Oops,  I did not find the GCN# you  provided. Are you sure it's valid?";

  }
 
  $sth->finish();
  
  # disconnect from database
  $dbh->disconnect;
  

 ( \%gcns, \@gcns_array );

}


sub get_all_closed_unplanned_major_gcns {


  my %gcns;
  my @gcns_array;

  my $dbh = NOC::get_dbh();

  my $stmt = qq[
                SELECT id,  short_description, type, criticality,  start_day_of_week, end_day_of_week, detection_day_of_week, start_time, est_end_time, detection_time, status , responsible_group, root_cause
                FROM outage
                WHERE status = 'closed' and type = 'unplanned' and criticality = 'major' and  responsible_group is not null and root_cause is not null
                ORDER BY type DESC, Field(criticality,'Major','Moderate','Minor'), start_time DESC
        ];


  my $sth = $dbh->prepare($stmt) or die "stmt error: " . $dbh->errstr;
  $sth->execute();


  # assign fields to variables
  my ($id, $short_description,  $type, $criticality, $start_day_of_week, $end_day_of_week, $detection_day_of_week, $start_time, $est_end_time, $detection_time,  $status, $responsible_group, $root_cause  );
  
  $sth->bind_columns(\$id, \$short_description,  \$type, \$criticality, \$start_day_of_week, \$end_day_of_week,  \$detection_day_of_week, \$start_time, \$est_end_time, \$detection_time, \$status, \$responsible_group, \$root_cause );
  

  my $record_exists;
  while ( $sth->fetch() ) {

      push @gcns_array, $id;
      $gcns{$id} = {
                short_description => $short_description, 
                type => $type, 
                criticality => $criticality, 
                start_day_of_week => $start_day_of_week, 
                end_day_of_week => $end_day_of_week, 
                detection_day_of_week => $detection_day_of_week, 
                start_time => $start_time, 
                est_end_time => $est_end_time ,
                detection_time => $detection_time, 
                status => $status, 
                responsible_group => $responsible_group, 
                root_cause => $root_cause, 
        };  

    $record_exists++;

  }

  unless ( $record_exists ) {

    print "Oops,  I did not find the GCN# you  provided. Are you sure it's valid?";

  }
 
  $sth->finish();
  
  # disconnect from database
  $dbh->disconnect;
  

  (\%gcns, \@gcns_array);

}





# 
view_detail( $id ) if $id;


# we are in "Advanced Search" fieldset
if ( param("submit") and param("submit") eq "Submit" ) {

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
		SELECT count(*) 
		FROM outage 
		WHERE type = 'unplanned'
		AND start_time >=  '$theDate0S' and est_end_time < '$theDate0E 23:59:59'
	];

    show_customized_query_results( $theDate0S, $theDate0E );
#    view_summary( $stmt );

  } 


  exit;

}


# no $id provided, view_summary

my $stmt = qq[
		SELECT id,  short_description, type, criticality,  start_day_of_week, end_day_of_week, detection_day_of_week, start_time, est_end_time, detection_time, status , responsible_group, root_cause
		FROM outage 
		WHERE status = 'closed' and type = 'unplanned' and criticality = 'major' and  responsible_group is not null and root_cause is not null
		ORDER BY type DESC, Field(criticality,'Major','Moderate','Minor'), start_time DESC
	];

view_summary( $stmt );



print end_html();


exit;
