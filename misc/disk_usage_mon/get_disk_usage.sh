#!/bin/bash
#
# lwang: get disk usage for a given env for one run
#
#
if [[ "`hostname`" != 'rotozip.corp' ]]; then
  echo "run it on rotozip."
  exit
fi

if [ ! $# -eq 1 ]; then
  cat <<USAGE

  $0 <env> 

e.g.,

  $0 beta 
	- this will run once in beta 

USAGE
  exit
fi

# now that we have the right number of args
env=$1

#echo $env


function get_all_hosts()  
{
#  hosts_all_file="$ITOPS_HOME/conf/hosts_${env}_all"
#  echo $hosts_all_file
  
  all_hosts=`$ITOPS_HOME/bin/cmtool.pl -act gethosts -env $env`
#  echo $all_hosts  

}


function check_itops_env_var() {
  if ! test $ITOPS_HOME; then
    echo
    echo 'You need to have ITOPS_HOME set to your itops repo root'
    echo
    exit
  fi
}

check_itops_env_var
get_all_hosts

echo $all_hosts

docroot=/export/content/http/i001/htdocs/cm/disk_usage_mon
ts=`date '+%m%d%H%M'`

for h in $all_hosts
do
	echo "======== $h ========"
	# in case the host asks "yes/no"
	$ITOPS_HOME/bin/say_yes $h
        if [[ ! -e "$docroot/$h" ]]; then
	  mkdir -pm 777 $docroot/$env
	  mkdir -pm 777 $docroot/$env/$h
        fi
	ssh $h "df -kh /export/content | tail -1" >  $docroot/$env/$h/$ts.txt
        chmod 777 $docroot/$env/$h/$ts.txt

done

exit
#############################################
