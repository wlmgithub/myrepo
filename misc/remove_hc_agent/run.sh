#!/bin/bash

sudo=/usr/local/bin/sudo

env=${1:?"Give me an env. e.g., ech3, beta, stg"}

#echo $env

hosts=`$ITOPS_HOME/bin/cmtool.pl -a gethosts -env $env`

#echo $hosts

echo "Enter password: "
stty -echo
read pwd
stty echo


for h in $hosts 
do

  echo $pwd | ssh $h  $sudo ls  >/dev/null  2>&1
  scp ./checkit.sh $h:~  >/dev/null 2>&1
#  ssh $h './checkit.sh; rm ./checkit.sh; ps -efa|grep java|grep -v grep ' 2>/dev/null
  ret=`ssh $h './checkit.sh | sort -u; rm ./checkit.sh ' 2>/dev/null`
  if [ -n "$ret" ]; then
    echo
    echo ===== $h
    echo $ret 
  else 
#    echo "would be running ssh $h 'cd /export/content; $sudo rm -rf agent' "
#    echo " running ssh $h 'cd /export/content; $sudo rm -rf agent'  "
    echo "removing /export/content/agent on $h"
    ssh $h  " cd /export/content;  $sudo rm -rf agent "  2>/dev/null
  fi

done
