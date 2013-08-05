#!/bin/bash

cd /export/content

non_glu_pids=$(find agent  -name  *.pid | xargs cat | sed 's/PID=//')

for p in $non_glu_pids
do
  ret=`/bin/ps -efa|grep java | grep $p`
  if [ -n "$ret" ]; then
#    echo "===$p==="
#    echo $ret
    /usr/local/bin/sudo pargs $p  | grep --  '-Dcom.foobar.app.name='  | grep argv  | sed -e 's/.*=//' | sort -u 
  fi
done
