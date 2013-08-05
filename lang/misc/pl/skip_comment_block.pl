
open $f, "skip_comment_block.txt";
  while (<$f>) {
    next if m{<!--} .. m{-->};
    print ;

  }
close $f
