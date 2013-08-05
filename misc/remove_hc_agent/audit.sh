#!/bin/bash

sudo=/usr/local/bin/sudo

env=${1:?"Give me an env. e.g., ech3, beta, stg"}

#echo $env

hosts=`$ITOPS_HOME/bin/cmtool.pl -a gethosts -env $env`

#echo $hosts


for h in $hosts 
do

  ssh $h  " cd /export/content;  if [ -e  "agent" ]; then hostname; echo 'still has /export/content/agent'; fi "  2>/dev/null

done
