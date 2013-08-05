#
# credit: https://github.com/mojombo/jekyll/blob/master/g.pl
#
open(GITLOG, qq/git log --pretty=format:"%ae|%an" |/) or die("failed to read git-log: $!\n");
while(<GITLOG>) {
  # process line by line
  print;
}
close GITLOG;
