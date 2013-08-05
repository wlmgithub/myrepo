#!/bin/bash

echo "checking..."

what="$1"

#find . -type f -exec grep -hl "$1" '{}' +
find . -type f -exec grep  -i "$1" '{}' +

exit

#find . -type f -exec grep -hl $what {} \;

#find . -type f | while read f; do echo $f; grep 'Please Enter Integer' $f; done

find . -type f | while read f
do
  if [ ! "X`grep $what $f`" == "X" ]; then
    echo
    echo ===== $f
    grep $what $f
  fi
done

