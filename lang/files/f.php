<?php
$h = array();
$fname = "foo.txt";
$fh = fopen($fname, "r") or die( "cannot open file: $fname\n" );
while (!feof($fh)) {
  $line = fgets($fh);
  $line = rtrim($line);
  if ( preg_match('/(.*)\s+(.*)/', $line, $m) ) {
    $k = $m[1];
    $v = $m[2];
    if (array_key_exists($k, $h)) {
      $h[$k] = $h[$k] + $v;
    }
    else {
      $h[$k] = $v;
    }
  }
#  print "$line\n";
}
  
fclose($fh);

foreach ( $h as $k => $v ) {
  print "$k\t$v\n";
}

?>
