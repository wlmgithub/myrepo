
use lib  '/Users/lwang/code/itops/lib/perl';

print "\n====\n";

print "@INC";
use Utils qw(in_A_not_in_B);


my @all = getit ( 'all' );
my @in944 = getit ( '944_s' );

my $res_ref = in_A_not_in_B ( \@all, \@in944 );
my @res = @$res_ref;


print "\n\nAll components in manifest_ech3 (count: ",  scalar @all, ")";
print "\n============================================\n";
print "@all\n";
#print "count: (", scalar @all, ")";

print "\n\nPushed in 944 (count: ",  scalar @in944, ")";
print "\n============================================\n";
print "@in944\n";
#print "count: (", scalar @in944, ")";


print "\n\nComponents NOT pushed (count: ", scalar @res, ")";
print "\n============================================\n";
print "@res\n";
#print "count: (", scalar @res, ")";
print "\n";


sub getit {
  my $file = shift;

  my @a;
  open my $f, "<", $file ;
  while (<$f>) {
    chomp;
    push @a, $_; 
  }
  close $f;

  @a;

}
