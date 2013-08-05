package MYCM;
#
# lwang: foobar Configuration Management Package
#
use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Carp;

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
	get_content_in_file
	prop_in_file
	is_frontend_app
	get_frontend_installed_dir
);


########################
# 
# package vars
#
########################
my $manifest_file = " ";

########################
# my subs
########################

sub get_manifest {

}

sub get_content_in_file {
  
  my $file = shift;

  my %hash;

  open my $f, "<", $file or croak "I cannot open file \"$file\": $!\n";

  while (<$f>) {
    chomp;
    next if /^#/;                 # use # as comment
    next if /^\s+$/;              # strip out blank lines
    s/\s+$//;                     # strip out last blanks

    $hash{$1} = $2 if /(.*)\t(.*)/;  # tab deliminated field

  }

  close $f;

  return \%hash;

}

sub prop_in_file {

  my $prop_string = shift;
  my $file = shift;

  my $in;

  open my $f, "<",  $file or die "cannot open $file for reading: $!\n";

  while (<$f>) {
    chomp;
    if ( /entry key=/ && m{<!--} && m{-->} ) {
      s{<!--}{}g;
      s{-->}{}g;
    }
    unless (/<!--/ .. /-->/) {
      $in = 1 if /key=\"$prop_string\"/;
    }
  }

  close $f;

  return $in;

}

sub is_frontend_app {

  my $app = shift;
  my $container_mapping_file = shift;

  open my $f, "<", $container_mapping_file or die "Cannot open file $container_mapping_file for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^#/;
    return 1 if /^$app\s+/; 
  }
  close $f;

  return;

}

sub get_frontend_installed_dir {

  my $app = shift;
  my $container_mapping_file = shift;

  open my $f, "<", $container_mapping_file or die "Cannot open file $container_mapping_file for reading: $!\n";
  while (<$f>) {
    chomp;
    next if /^#/;
    return $1 if /^$app\t(.*)/; 
  }
  close $f;

  return;

}



###############
1;                           # make perl happy 

__END__

