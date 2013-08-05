#!/bin/bash
# lwang: grep beta boxes in alpha public log files
#
for f in `ls /export/content/*/i0[0-9][0-9]/logs/*public_access.log` ; do
  #echo === $f
  if test -e "$f"; then
    for h in `cat hosts_beta_all`; do
      #echo -e "\t${h%.stg}"
      tail -1000 $f | grep -i ${h%.stg}
    done
  fi
done
