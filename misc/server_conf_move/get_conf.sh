#!/bin/bash

if [ $# -ne 2 ]
then
    echo "Usage : $0 <ccs_root> <manifest>"
    exit 1
fi

ccs_root=$1
manifest=$2

#~/stg_server_conf
#~/code/itops/manif/manifest_stg

tmp_dir=/tmp/tmp_conf
mkdir -p ${tmp_dir}

while read app
do
  echo ${app} | grep tomcat #> /dev/null 2>&1
  if [ $? -eq 1 ]
  then
    cont_root=`echo ${app} | cut -f1 -d" "`
    if [ "$cont_root" = "agent" ]
    then
      continue
    fi
    machines=`echo ${app} | cut -f2- -d" "`

    for host in $machines
    do

      echo ""
      h=`echo ${host} | cut -f1 -d"."`
      echo "getting server_conf.sh for $cont_root on ${host}"

      ccs_dir=${ccs_root}/${cont_root}/${h}
      mkdir -p ${ccs_dir}
      if [ ! -f ${tmp_dir}/${host}.tar ]
      then
	ssh -n $host "cd /export/content/; tar cvf /tmp/${host}.tar */conf/server_conf.sh */i0[0-9][0-9]/conf/server_conf.sh;" > /dev/null 2>&1
	scp $host:/tmp/${host}.tar ${tmp_dir} > /dev/null 2>&1
	ssh -n $host "rm /tmp/${host}.tar" > /dev/null 2>&1
      fi

      pushd ${ccs_dir} > /dev/null 2>&1

      tar xvf ${tmp_dir}/${host}.tar ${cont_root} > /dev/null 2>&1
      if [ $? -eq 0 ]
      then
	mv ${cont_root}/* .
	rmdir ${cont_root}
      else
	echo "	WARNING : wrong container, no server_conf.sh or wrong manifest for ${cont_root} on ${host} ?????"
	popd > /dev/null 2>&1
	continue
      fi

      for d in `ls`
      do
	if [ -d $d ]
	then
	  if [ "`basename $d`" = "conf" ]
	  then
	    mv $d/* .; rmdir $d;
	  else
	    echo "	$d ...."
	    cd $d; mv conf/* .; rmdir conf; cd ../ 
	  fi 
	fi
      done
      popd > /dev/null 2>&1
    done
  fi
done < $manifest

rm ${tmp_dir}/*
