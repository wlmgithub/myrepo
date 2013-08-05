#!/usr/local/perl/bin/perl -wT
#!/bin/perl -wT
use strict;
use CGI qw(:standard);
use DBI;

use POSIX qw(strftime);
use Time::Local;

use lib '.';
use NOC;

# from CPAN
use Date::Simple;
use Date::Range;


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

  print start_form( -id => 'advanced_search', -name => 'advanced_search', -method => 'GET' );

  print "<fieldset>";
  print "<legend> Monthly Report Query </legend>";

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

<!--
<tr><td> From:  </td><td><input type="text" value="$now" readonly="readonly"  name="theDate0S" id="theDate0S">   </td><td> <input type="button" value="Cal" onclick="displayCalendar(document.getElementById('advanced_search').theDate0S ,'yyyy-mm-dd',this)">   </td></tr>

<tr><td> To:  </td><td> <input type="text" value="$now" readonly="readonly"  name="theDate0E" id="theDate0E">   </td><td> <input type="button" value="Cal" onclick="displayCalendar(document.getElementById('advanced_search').theDate0E ,'yyyy-mm-dd',this)">    </td> </tr>
-->

<tr><td> Select:  </td><td> 
<select name="number_of_months" id="number_of_months">
  <option selected='selected' value='3'> Last 3 months </option>
  <option  value='6'> Last 6 months </option>
  <option  value='9'> Last 9 months </option>
  <option  value='12'> Last 12 months </option>
</select>
</td> </tr>


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

  my $date_from = shift;
  my $date_to = shift;
  my $type = shift;
  my $criticality = shift;

  my $stmt = qq[
                SELECT id
                FROM outage
               ];

  if ( $type and $criticality ) {
    $stmt .= qq [  WHERE type = '$type' and criticality = '$criticality' ];
  }
  else {
    $stmt .= qq[  WHERE type = '$type' ];
  }

  $stmt .= qq[ 
                AND start_time >=  '$date_from' and start_time < '$date_to 23:59:59'
             ];


  my $dbh = NOC::get_dbh();

  my $query = $stmt;

  my $sth = $dbh->prepare($query);
  $sth->execute();

  my @ids;
  while( my @a  = $sth->fetchrow_array() ) {
    push @ids, @a;
  }

  return \@ids;

#  my $rs = $sth->fetchall_arrayref();

#  return $rs->[0]->[0];

}

sub get_details_for_id {

  my $id = shift;

  my $stmt = qq[
                SELECT short_description
                FROM outage
                WHERE id = ?
               ];

  my $dbh = NOC::get_dbh();

  my $query = $stmt;

  my $sth = $dbh->prepare($query);
  $sth->execute($id);

  my $short_description;

  $sth->bind_columns( \$short_description );

  while( $sth->fetch() ) {
    return $short_description;
  }

}

sub get_all_dates {

  my $theDate0S = shift;
  my $theDate0E = shift;

  my $start_date = Date::Simple->new($theDate0S);
  my $end_date = Date::Simple->new($theDate0E);

  my $range = Date::Range->new( $start_date, $end_date );
  my @dates = $range->dates;

  \@dates;

}


sub get_show_date {
  my $date = shift;
  my $show_date = $date;
  $show_date = $1 if $show_date =~ /\d{4}-(.*)/;
  return $show_date; 
}


sub show_customized_query_results {

  my $dates_from_ref = shift;
  my $dates_to_ref = shift;
  my $total_unplanned_ref = shift;
  my $total_unplanned_major_ref = shift;
  my $total_unplanned_moderate_ref = shift;
  my $total_planned_ref = shift;

  my @dates_from = @{$dates_from_ref};
  my @dates_to = @{$dates_to_ref};

#  pop @dates_to;
  #
  # now @dates_from and @dates_to are reversed !!!
  #
  @dates_from = reverse @dates_from;   
  @dates_to = reverse @dates_to;

  # date_from -> date_to  -> total # 
  my %total_unplanned = %{$total_unplanned_ref};
  my %total_unplanned_major = %{$total_unplanned_major_ref};
  my %total_unplanned_moderate = %{$total_unplanned_moderate_ref};
  my %total_planned = %{$total_planned_ref};

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


  my $table;
#  my $phpurl = "https://gcn.corp.foobar.com/noc/report/daily/index.php?form_submitted=1&theDate0S=$date_start&theDate0E=$date_end";
#  my $url = $phpurl;

  $table .= "<table border='1'>";


  # date row
  $table .= "<tr>";
  $table .= "<th> Month Starting </th>";
  for my $date ( @dates_from ) {
    my $show_date = get_show_date($date);
    $table .= "<th>  $show_date </th>";
  }
#  $table .= "<th></th>";
  $table .= "</tr>";
  
  $table .= "<tr>";
  $table .= "<th> Month Ending</th>";
  for my $date ( @dates_to ) {
    my $show_date = get_show_date($date);
    $table .= "<th>  $show_date </th>";
  }
#  $table .= "<th></th>";
  $table .= "</tr>";


  # unplanned row
  $table .= "<tr> <th> Unplanned Total </th>";
  for ( 0 .. $#dates_from  ) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    if ( $total_unplanned{$date_from}{$date_to} ) {
      $table .= "<td> <a href='?list_gcns=1&type=unplanned&date_from=$date_from&date_to=$date_to'> $total_unplanned{$date_from}{$date_to} </a> </td>";
    }
    else {
      $table .= "<td> $total_unplanned{$date_from}{$date_to} </td>";
    }
  }

#  $url = $phpurl . "&theType=unplanned_total";
#  $table .= "<th><a href='$url'> graph </a></th>";
  $table .= "</tr>";
 


  # unplanned major row
  $table .= "<tr> <th> Unplanned Major</th>";
  for ( 0 .. $#dates_from ) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    if ( $total_unplanned_major{$date_from}{$date_to} ) {
       $table .= "<td> <a href='?list_gcns=1&type=unplanned&criticality=major&date_from=$date_from&date_to=$date_to'> $total_unplanned_major{$date_from}{$date_to} </a> </td>";
    } 
    else {
      $table .= "<td> $total_unplanned_major{$date_from}{$date_to} </td>";
    }
  }

#  $url = $phpurl . "&theType=unplanned_major";
#  $table .= "<th><a href='$url'> graph </a></th>";
  $table .= "</tr>";

  # unplanned moderate row
  $table .= "<tr> <th> Unplanned Moderate</th>";
  for ( 0 .. $#dates_from ) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    if ( $total_unplanned_moderate{$date_from}{$date_to} ) {
      $table .= "<td> <a href='?list_gcns=1&type=unplanned&criticality=moderate&date_from=$date_from&date_to=$date_to'> $total_unplanned_moderate{$date_from}{$date_to} </a> </td>";
    }
    else {
      $table .= "<td> $total_unplanned_moderate{$date_from}{$date_to} </td>";
    }
  }

#  $url = $phpurl . "&theType=unplanned_moderate";
#  $table .= "<th><a href='$url'> graph </a></th>";
  $table .= "</tr>";

  # planned row
  $table .= "<tr> <th> Planned </th>";
  for ( 0 .. $#dates_from ) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    if ( $total_planned{$date_from}{$date_to} ) {
      $table .= "<td> <a href='?list_gcns=1&type=planned&date_from=$date_from&date_to=$date_to'> $total_planned{$date_from}{$date_to} </a> </td>";
    }
    else {
      $table .= "<td> $total_planned{$date_from}{$date_to} </td>";
    }
  }

#  $url = $phpurl . "&theType=planned_total";
#  $table .= "<th><a href='$url'> graph </a></th>";
  $table .= "</tr>";
 
  $table .= "</table>";


  print $table;




######################### add googlechart here
# http://code.google.com/apis/chart/interactive/docs/gallery/linechart.html
#

###### gchart starting part
  my $gchart = <<GCHART;

    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = new google.visualization.DataTable();  // data: total_unplanned
        var data2 = new google.visualization.DataTable(); // data2: total_unplanned_major
        var data3 = new google.visualization.DataTable(); // data3: overlay
        var data4 = new google.visualization.DataTable(); // data4: total_unplanned_moderate
        var data5 = new google.visualization.DataTable(); // data5: total_planned

GCHART

###### gchart data part

  my $number_of_days = $#dates_from+1;

  ######### total unplanned
  $gchart .= qq( 
    data.addColumn('string', 'Day');
    data.addColumn('number', 'Total Unplanned');
    data.addRows($number_of_days);
  ); 

  for  (0 .. $#dates_from) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    my $show_date = get_show_date($date_from);
    $gchart .= qq(
      data.setValue($_, 0, '$show_date');
      data.setValue($_, 1, $total_unplanned{$date_from}{$date_to});
    );
  }

  ######### total unplanned major
  $gchart .= qq( 
    data2.addColumn('string', 'Day');
    data2.addColumn('number', 'Total Unplanned Major');
    data2.addRows($number_of_days);
  ); 

  for  (0 .. $#dates_from) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    my $show_date = get_show_date($date_from);
    $gchart .= qq(
      data2.setValue($_, 0, '$show_date');
      data2.setValue($_, 1, $total_unplanned_major{$date_from}{$date_to});
    );
  }

  ######### overlay
  $gchart .= qq( 
    data3.addColumn('string', 'Day');
    data3.addColumn('number', 'Total Unplanned');
    data3.addColumn('number', 'Total Unplanned Major');
    data3.addRows($number_of_days);
  ); 

#    data3.addColumn('number', 'Total Unplanned Moderate');
#    data3.addColumn('number', 'Total Planned');

  for  (0 .. $#dates_from) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    my $show_date = get_show_date($date_from);
    $gchart .= qq(
      data3.setValue($_, 0, '$show_date');
      data3.setValue($_, 1, $total_unplanned{$date_from}{$date_to});
      data3.setValue($_, 2, $total_unplanned_major{$date_from}{$date_to});
    );
  }

#      data3.setValue($_, 3, $total_unplanned_moderate{$date});
#      data3.setValue($_, 4, $total_planned{$date});

  ######### total unplanned moderate
  $gchart .= qq( 
    data4.addColumn('string', 'Day');
    data4.addColumn('number', 'Total Unplanned Moderate');
    data4.addRows($number_of_days);
  ); 

  for  (0 .. $#dates_from) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    my $show_date = get_show_date($date_from);
    $gchart .= qq(
      data4.setValue($_, 0, '$show_date');
      data4.setValue($_, 1, $total_unplanned_moderate{$date_from}{$date_to});
    );
  }

  ######### total planned
  $gchart .= qq( 
    data5.addColumn('string', 'Day');
    data5.addColumn('number', 'Total Planned');
    data5.addRows($number_of_days);
  ); 

  for  (0 .. $#dates_from) {
    my $date_from = $dates_from[$_];
    my $date_to = $dates_to[$_];
    my $show_date = get_show_date($date_from);
    $gchart .= qq(
      data5.setValue($_, 0, '$show_date');
      data5.setValue($_, 1, $total_planned{$date_from}{$date_to});
    );
  }



###### gchart closing part
  my $width = 1200;
  my $height = 310;

  $gchart .= qq(

        var chart = new google.visualization.LineChart(document.getElementById('chart_div_overlay'));
        chart.draw(data3, {width: $width, height: $height, title: 'Overlay'});

        var chart = new google.visualization.LineChart(document.getElementById('chart_div_total_unplanned'));
        chart.draw(data, {width: $width, height: $height,  title: 'Total Unplanned'});

        var chart = new google.visualization.LineChart(document.getElementById('chart_div_total_unplanned_major'));
        chart.draw(data2, {width: $width, height: $height, colors: [ 'red', '#0F0'], title: 'Total Unplanned Major'});

        var chart = new google.visualization.LineChart(document.getElementById('chart_div_total_unplanned_moderate'));
        chart.draw(data4, {width: $width, height: $height, colors: ['orange'], title: 'Total Unplanned Moderate'});

        var chart = new google.visualization.LineChart(document.getElementById('chart_div_total_planned'));
        chart.draw(data5, {width: $width, height: $height,  colors: ['#0F0'], title: 'Total Planned'});


      }
    </script>

    <div id="chart_div_overlay"></div>
    <div id="chart_div_total_unplanned"></div>
    <div id="chart_div_total_unplanned_major"></div>
    <div id="chart_div_total_unplanned_moderate"></div>
    <div id="chart_div_total_planned"></div>

  );

  print $gchart;




######################### end googlechart here

 
  exit;

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

sub get_end_dates_ref_of_last_x_months {
  
  my $x = shift;
  my @dates;
  
  my $today = get_time_now();
  my ($y, $m, $d) = ($1, $2, $3) if $today =~ /(\d{4})-(\d{2})-(\d{2})/;

  # if today is not the first day of current month
  #  starting with today
  if ( $d > 1 ) {
    unshift @dates, $today;
    $x--;
  }

  # if today is the first day of current month
  #  starting with last month's last day
  for (1 .. $x ) {
    $m--;
    $m = sprintf("%02d", $m); 
    if ( $m == 0 ) {
      $m = 12;
      $y--;
      $y = sprintf("%04d", $y);
    }

    if ( grep(/\b$m\b/, ('01','03','05','07','08','10','12') ) ) {
      unshift @dates, "$y-$m-31";
    } elsif (  grep(/\b$m\b/, ('04','06','09','11') ) ) {
      unshift @dates, "$y-$m-30";
    } elsif ( $m == 2 && $y == 2012 ) {
      unshift @dates, "$y-$m-29";
    } elsif ( $m == 2 ) {
      unshift @dates, "$y-$m-28";
    }

  }

  @dates = reverse @dates;
  \@dates;

}


sub get_start_dates_ref_of_last_x_months {
  
  my $x = shift;
  my @dates;
  
  my $today = get_time_now();
  my ($y, $m, $d) = ($1, $2, $3) if $today =~ /(\d{4})-(\d{2})-(\d{2})/;

  # if today is not the first day of current month
  #  starting with current month's first day
  if ( $d > 1 ) {
    unshift @dates, "$y-$m-01";
    $x--;
  }

  # if today is the first day of current month
  # starting with last month's first day 
  for (1 .. $x ) {
    $m--;
    $m = sprintf("%02d", $m); 
    if ( $m == 0 ) {
      $m = 12;
      $y--;
      $y = sprintf("%04d", $y);
    }
    unshift @dates, "$y-$m-01";
  }

  @dates = reverse @dates;
  \@dates;

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


sub show_gcns_list {

  my $date_from = param("date_from");
  my $date_to = param("date_to");
  my $type = param("type");
  my $criticality = param("criticality");

  my $gcns_ref = get_stmt_result( $date_from, $date_to, $type, $criticality );

  my $table = qq( <table> );

  for my $gcn ( @{$gcns_ref} ) {

    my $desc = get_details_for_id($gcn);

    $table .= qq(
      <tr>
      <td> <a href='?id=$gcn'> $gcn  </a>  :  </td>
      <td> $desc  </td>
      </tr>
    );
  }

  $table .= qq( </table> );

  print $table;

  exit;

}




###############################################  
view_detail( $id ) if $id;

if ( param("list_gcns") ) {
  
    show_gcns_list();
  
}


# we are in "Advanced Search" fieldset
if ( param("submit") and param("submit") eq "Submit" ) {

  my $number_of_months = param("number_of_months");

  my $ref = get_start_dates_ref_of_last_x_months($number_of_months);

  my @dates = @$ref;

#  print "@dates<p>";

#  my $today = get_time_now();

#  my @temp_dates = @dates;
#  unshift @temp_dates, $today;

  $ref = get_end_dates_ref_of_last_x_months($number_of_months);

  my @temp_dates = @$ref;

=pod
  print "@temp_dates<p>";

  for (0 .. $#dates) {
    print " $_ : $dates[$_] : $temp_dates[$_]<p>";
  }
=cut

  
  # date -> ids ref
  my %unplanned;
  my %unplanned_major;
  my %unplanned_moderate;
  my %planned;

  # date -> total # 
  my %total_unplanned;
  my %total_unplanned_major;
  my %total_unplanned_moderate;
  my %total_planned;

  for (0 .. $#dates) {

    my $date_from = $dates[$_];
    my $date_to = $temp_dates[$_];

    $unplanned{$date_from}{$date_to} = get_stmt_result( $date_from, $date_to, 'unplanned' );  # ids ref 
    $unplanned_major{$date_from}{$date_to} = get_stmt_result( $date_from, $date_to, 'unplanned', 'major' );  # ids ref 
    $unplanned_moderate{$date_from}{$date_to} = get_stmt_result( $date_from, $date_to, 'unplanned', 'moderate' );  # ids ref 
    $planned{$date_from}{$date_to} = get_stmt_result( $date_from, $date_to, 'planned' );  # ids ref 

    $total_unplanned{$date_from}{$date_to} = @{$unplanned{$date_from}{$date_to}};
    $total_unplanned_major{$date_from}{$date_to} = @{$unplanned_major{$date_from}{$date_to}};
    $total_unplanned_moderate{$date_from}{$date_to} = @{$unplanned_moderate{$date_from}{$date_to}};
    $total_planned{$date_from}{$date_to} = @{$planned{$date_from}{$date_to}};
  }
  


  # @dates : @dates_from
  # @temp_dates: @dates_to
  show_customized_query_results( \@dates, \@temp_dates,  \%total_unplanned, \%total_unplanned_major, \%total_unplanned_moderate, \%total_planned );

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
