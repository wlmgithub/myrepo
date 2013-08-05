#!/bin/bash

cd /export/content

non_glu_pids=$(find `ls  |egrep -v '^glu'` -name  *.pid | xargs cat | sed 's/PID=//')

#echo $non_glu_pids

for p in $non_glu_pids
do
  ret=`/bin/ps -efa|grep java | grep $p`
  if [ -n "$ret" ]; then
#    echo "===$p==="
#    echo $ret
    /usr/local/bin/sudo pargs $p  | grep --  '-Dcom.foobar.app.name='  | grep argv  | sed -e 's/.*=//' | grep -v agent | sort -u 
  fi
done
