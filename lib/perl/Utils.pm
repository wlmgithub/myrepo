package Utils;
#
# lwang: perl utilities 
#
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

#@EXPORT      = qw(...);       # Symbols to autoexport (:DEFAULT tag)
#@EXPORT_OK   = qw(...);       # Symbols to export on request
#%EXPORT_TAGS = (              # Define names for sets of symbols
#    TAG1 => [...],
#    TAG2 => [...],
#    ...
#);

@EXPORT_OK = qw(
	union_of_A_and_B
	intersection_of_A_and_B
	diff_of_A_and_B
	in_A_not_in_B
	array_unique
);

########################
# my subs
########################
sub union_of_A_and_B {
  my $ref_A = shift;
  my $ref_B = shift;

  my %count;
  my @union;

  foreach my $e ( @$ref_A, @$ref_B ) { $count{$e}++ }

  foreach my $e (keys %count) {
    push @union, $e;
  }

  return \@union;
}


###############
sub intersection_of_A_and_B {
  my $ref_A = shift;
  my $ref_B = shift;

  my %count;
  my @isect;

  foreach my $e ( @$ref_A, @$ref_B ) { $count{$e}++ }

  foreach my $e (keys %count) {
    if ($count{$e} == 2) {
      push @isect, $e;
    }
  }

  return \@isect;
}

###############
sub in_A_not_in_B {
  my $ref_A = shift;
  my $ref_B = shift;

  my %seen; # lookup table
  my @aonly;# answer
  
  # build lookup table
  @seen{@$ref_B} = ();
  
  foreach my $item (@$ref_A) {
      push(@aonly, $item) unless exists $seen{$item};
  }

  @aonly = sort(@aonly);

  return \@aonly;
}


###############
sub diff_of_A_and_B {
  my $ref_A = shift;
  my $ref_B = shift;

  my %count;
  my @diff;

  foreach my $e ( @$ref_A, @$ref_B ) { $count{$e}++ }

  foreach my $e (keys %count) {
    if ($count{$e} != 2) {
      push @diff, $e;
    }
  }

  return \@diff;
}

###############
sub array_unique {

  my $ref_in = shift;
  my @in = @$ref_in;

  my %saw;

  undef %saw;
  my @out = grep(!$saw{$_}++, @in);

  return \@out;

}


###############
sub get_timestamp {

  #my @time_data = localtime(time);
  #
  # 0 - sec
  # 1 - min
  # 2 - hr
  # 3 - day
  # 4 - mon
  # 5 - year
  # 6 - day of week
  # 7 - day of year
  # 8 - daylight?
  #
  
  #print @time_data;
  #print @time_data[0,1,2,3,4,5,6,7,8] ;
  #print $time_data[0],"\t";
  #print $time_data[1],"\t";
  #print $time_data[2],"\t";
  #print $time_data[3],"\t";
  #print $time_data[4]+1,"\t";
  #print $time_data[5]+1900,"\t";
  #print $time_data[6],"\t";
  #print $time_data[7],"\t";
  #print $time_data[8],"\t";
  #print "\n";
  
  #my $year =  $time_data[5]+1900;
  #my $month = sprintf("%02d", $time_data[4]+1);
  #my $day =  sprintf("%02d",$time_data[3]);
  
  #print "$year/$month/$day\n";

}

###############
1;                           # make perl happy 

__END__

use Utils qw(union_of_A_and_B intersection_of_A_and_B diff_of_A_and_B);

@a = qw( a b c d e f);
@b = qw( d e f g h p);

my $ref_union = union_of_A_and_B(\@a, \@b);;
my $ref_isect = intersection_of_A_and_B(\@a, \@b);;
my $ref_diff = diff_of_A_and_B(\@a, \@b);;
my $ref_A_not_B = in_A_not_in_B(\@a, \@b);


print "\@a: @a\n";
print "\@b: @b\n";
print "union: @$ref_union\n";
print "isect: @$ref_isect\n";
print "diff: @$ref_diff\n";
print "in_A_not_in_B: @$ref_A_not_B\n";
