my $h;

open my $f, "foo.txt" or die "cannot open file: $!\n";
while(<$f>) {
  chomp;
  if ( /(.*)\s+(.*)/ ) {
    $h{$1} += $2;
  }
}
close $f;

while ( my ($k, $v) = each %h ) {
  print "$k\t$v\n";
}
