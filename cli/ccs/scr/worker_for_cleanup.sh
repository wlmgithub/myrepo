#!/bin/bash
# 
#  <scr>  /export/content/repository/STG-BETA notifier "<optional args>"
#
# WARNING!!!! 
#   DO NOT MANUALLY RUN IT UNLESS YOU ARE SURE WHAT YOU ARE DOING 
# WARNING!!!! 
#
root_dir=$1
ccsdir=$2
cd $root_dir/$ccsdir

if [ -z "$3" ]; then
  /bin/find . -type d -name "0.0.*"  | sed -e 's/\.\/0\.0\.//'
else
  # do cleanup 
  for i in $3; do
    /bin/rm -rf  $i
  done 
fi
