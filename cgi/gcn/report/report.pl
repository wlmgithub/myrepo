#!/usr/local/perl/bin/perl -w
#
# lwang: based on create.cgi
#
use strict;
use lib '.';
use NOC;

use POSIX  qw(strftime);
use DBI;

use Getopt::Long;

my $start;
my $end;
my $help;
my $sendto;

GetOptions(
  "start=s" => \$start,
  "end=s" => \$end,
  "sendto=s" => \$sendto,
  "help" => \$help,
);

my $usage =<<USAGE;

  usage: $0 [ --help ] --start '<start_date>' --end '<end_date>' --sendto '<recipients_list>'

e.g.,

	$0 --start '2010-08-08' --end '2010-08-15' --sendto 'noc\@foobar.com,lwang\@foobar.com' 

NOTES:
	1) if no --start and --end provided, --end defaults to today's date and --start defaults to seven days ago.
	2) if --sendto is not provided, it defaults to: 'nocstaff\@foobar.com,gcn-report\@foobar.com' 


USAGE

if ( $help ) {
  print $usage; exit;
}


my $http_proto = $NOC::http_proto;
my $server_name = 'gcn.corp.foobar.com';
my $view_script = '/cgi-bin/noc/outage/view.cgi';


my $this_day = $end ? $end : strftime "%Y-%m-%d", localtime(time);  # this_day is a misnomer, it's whatever end date provided, if any, otherwise, it's today's date
my $seven_days_ago = $start ? $start : seven_days_ago();      # seven_days_ago is a misnomer, it's whatever start date provided, if any, otherwise, it's seven days ago


#my %gcns = get_gcns();
my ($gcns_hashref, $gcns_arrayref )  = get_gcns();
send_email( $gcns_hashref, $gcns_arrayref );

exit;


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


  my %gcns;
  my @gcns_array;

  my $dbh = NOC::get_dbh();

  my $stmt = qq[
                SELECT id, short_description, rt_ticket, jira_ticket, type, criticality, start_day_of_week, end_day_of_week, start_time, est_end_time, status  
                FROM outage 
                WHERE
                start_time >=  '$seven_days_ago' and start_time <= '$this_day 23:59:59'
                ORDER BY type DESC, Field(criticality,'Major','Moderate','Minor'), start_time DESC
        ];

  my $sth = $dbh->prepare($stmt) or die "stmt error: " . $dbh->errstr;
  $sth->execute( );


  # assign fields to variables
  my ($id, $short_description, $rt_ticket, $jira_ticket,  $type, $criticality, $start_day_of_week, $end_day_of_week, $start_time, $est_end_time, $status );
  
  $sth->bind_columns(\$id, \$short_description, \$rt_ticket, \$jira_ticket, \$type, \$criticality, \$start_day_of_week, \$end_day_of_week, \$start_time, \$est_end_time, \$status );
  

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



sub send_email {

  my ($gcns_hashref, $gcns_arrayref) = @_;     
  my %gcns = %$gcns_hashref;
 
  $ENV{PATH} = '/usr/lib';
  
  my $sendmail = "/usr/lib/sendmail -t -f root";
  

  my $contact = $sendto ? $sendto : 'nocstaff@foobar.com,gcn-report@foobar.com,lwang@foobar.com';
#  my $contact = 'gcn-report@foobar.com,lwang@foobar.com';

#  my $send_from = "Reply-to: $owner\n";
  my $send_to = "To: $contact\n";
  my $subject = "Subject: GCN Report from $seven_days_ago to  $this_day\n";
  my $content_type = "Content-Type: text/html\n\n"; 

  my $content ;

   	$content .= "<p><br />";
   	$content .= "<hr />";
   	$content .= "<h2> GCN Report from $seven_days_ago to  $this_day </h2> \n";
   	$content .= "<hr> \n";
   	$content .= "<table border='1'>\n";
        
	$content .= " 

	<tr>
	<th> <b>Outage# </b></th>
	<th> <b>Short Description  </b></th>
	<th> <b>RT/JIRA#  </b></th>
	<th> <b>Outage Start Time &nbsp; </b> </th>
	<th> <b>Outage End Time &nbsp;  </b></th>
	<th> <b>Outage Type &nbsp;  </b></th>
	<th> <b>Criticality &nbsp; </b> </th>
	<th> <b>Status &nbsp; </b> </th>
	</tr>
	
	";
   
#        for my $id ( keys %gcns ) {
        for my $id ( @{$gcns_arrayref}  ) {

          my $short_description = $gcns{$id}->{'short_description'};
          my $type = $gcns{$id}->{'type'};
          my $criticality = $gcns{$id}->{'criticality'};
          my $rt_ticket = $gcns{$id}->{'rt_ticket'} || '';
          my $jira_ticket = $gcns{$id}->{'jira_ticket'} || '';
          my $status = $gcns{$id}->{'status'};
          my $start_day_of_week = $gcns{$id}->{'start_day_of_week'};
          my $end_day_of_week = $gcns{$id}->{'end_day_of_week'};
          my $start_time = $gcns{$id}->{'start_time'};
          my $est_end_time = $gcns{$id}->{'est_end_time'};


	  if (  $type =~ /unplanned/i &&  $criticality =~ /major/i ) {
	    $content .=  "<tr bgcolor='red'>\n";
	  }
	  elsif ( $type =~ /unplanned/i &&  $criticality =~ /moderate/i   ) {
	    $content .=  "<tr bgcolor='#F88017'>\n";   # dark orange
	  }
	  elsif ( $type =~ /unplanned/i &&  $criticality =~ /minor/i   ) {
	    $content .=  "<tr bgcolor='#41627E'>\n";   # sky blue
	  }
 	  else {
	    $content .=  "<tr >\n";
	  }

	  my ( $show_start_year, $show_start_month, $show_start_day, $show_start_rest ) =  get_time_fragments( "$start_time" );
	  my ( $show_end_year, $show_end_month, $show_end_day, $show_end_rest ) =  get_time_fragments( "$est_end_time" );

   	  $content .= "<td>   <a  href='${http_proto}://$server_name$view_script?id=$id'>  $id   </a>  </td> \n";
   	  $content .= "<td>   $short_description </td> \n";
	  
	  # rajeev wants to squeeze both RT and JIRA tickets into one column shown. it's "either o" case
	  if ( $rt_ticket ) {
	    $content .=  "<td> <a href=' https://siteops-rt.corp.foobar.com/Ticket/Display.html?id=$rt_ticket '  target='_blank' > $rt_ticket </td>";
	  }
	  elsif ( $jira_ticket ) {
	    $content .= "<td> <a href=' https://jira01.corp.foobar.com:8443/browse/$jira_ticket '  target='_blank' > $jira_ticket </td>";
	  }
	  else {
	    $content .=  "<td>   </td>";
	  }
   	  #$content .= "<td>   <a href=' https://siteops-rt.corp.foobar.com/Ticket/Display.html?id=$rt_ticket '  target='_blank' > $rt_ticket </a>  </td> \n";
   	  #$content .= "<td>   <a href=' https://iwww.corp.foobar.com/ist/jira/browse/$jira_ticket '  target='_blank' >  $jira_ticket  </a> </td> \n ";
	  #$content .= "<td> <a href=' https://iwww.corp.foobar.com/ist/jira/browse/$jira_ticket '  target='_blank' > $jira_ticket </td>";


   	  $content .= "<td>$start_day_of_week $show_start_day $show_start_month $show_start_year $show_start_rest  </td> \n";
   	  $content .= "<td>$end_day_of_week $show_end_day $show_end_month $show_end_year $show_end_rest  </td> \n";
   	  $content .= "<td>$type</td> \n";
   	  $content .= "<td>$criticality</td> \n";
   	  $content .= "<td>$status</td> \n";
   	  $content .= "</tr> \n";




        }

   	$content .= "</table>\n";

   	$content .= "\n<br>";

	$content .= "\n\n<p>";


  open( MAIL, "|$sendmail ")  or die "cannot open $sendmail: $!\n";
  print MAIL $subject;
  print MAIL $send_to;
  print MAIL $content_type;
  print MAIL $content;
  close MAIL;

}


sub send_email_orig {

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
	$end_day_of_week,
	$start_time,
	$end_time,
	$status,
	     
  ) = 	 @_ ;
 
  $ENV{PATH} = '/usr/lib';
  
  $creator =~ s{\@foobar.com}{}; # since we have @foobar.com appended to creator id...

  $creator = quotemeta( $creator );
  my $sendmail = "/usr/lib/sendmail -t -f $creator";
  
  $creator .= '@foobar.com';  #  rajeev wants to have @linkdin.com appended in the email

  # replace any https/http part anywhere in description with an anchor
  $description =~ s{(https?[^\s]*)}{<a href='$1'> $1 </a>}ixms ;

  $description =~ s/\n/\n<br>/g;
  $end_user_instruction =~ s/\n/\n<br>/g;
  $comments =~ s/\n/\n<br>/g;

  $start_time =~ s/:$//;
  $end_time =~ s/:$//;
  
  $created_or_updated = 'Closed' if $status =~ /closed/i;

  my $send_from = "Reply-to: $owner\n";
  my $send_to = "To: $contact\n";
  my $subject = "Subject: GCN $last_insert_id $created_or_updated - $type: $short_description \n";
  my $content_type = "Content-Type: text/html\n\n"; 

  my $content ;

   	$content .= "<p><br />";
   	$content .= "<hr />";
   	$content .= "<h2> Production Operations Global Change Notice </h2>";
   	$content .= "<hr>";
   	$content .= "<table>";
   	$content .= "<tr><td> <b>GCN#  </b>  </td><td>:  <a  href='${http_proto}://$server_name$view_script?id=$last_insert_id'>  $last_insert_id   </a>   </td></tr> ";
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
	$content .= "<tr><td> <b>Impacted services</b>  </td><td>: $impacted_services </td></tr>  ";
	$content .= "<tr><td> <b>Start Time</b>  </td><td>: $start_day_of_week $start_time  </td></tr>  ";
	$content .= "<tr><td> <b>Estimated End Time</b>  </td><td>: $end_day_of_week $end_time </td></tr>  ";
   	$content .= "</table>";

   	$content .= "\n<br>";

	$content .= "<b>Problem Description and Updates:</b> \n<p>$description\n<p>";
	$content .= "<b>End user instruction:</b> \n<p>$end_user_instruction\n<p>";
	$content .= "<b>Comments:</b> \n<p>$comments\n<p>";

	$content .= "\n\n<p>";


  open( MAIL, "|$sendmail ")  or die "cannot open $sendmail: $!\n";
  print MAIL $send_from;
  print MAIL $subject;
  print MAIL $send_to;
  print MAIL $content_type;
  print MAIL $content;
  close MAIL;

}


####TOTO
