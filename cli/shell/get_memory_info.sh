#!/bin/bash
#
# lwang: get memory info
#
if [  "x$ITOPS_HOME" = "x" ]; then
  echo "You need to have environment variable ITOPS_HOME set: e.g., export ITOPS_HOME=~/code/itops"
  exit
fi

ssh=/bin/ssh

function usage() {

  echo " "
  echo "usage: $0 [-h] [-e <environment>] "
  echo " "
  echo "e.g., $0 -e stg"
  echo " "
  echo " "
}


if [ $# = 0 ]; then
  usage
  exit 0
fi

while getopts ":he:" opt; do
  case $opt in
    h )
      usage
      exit 0
      ;;
    e )
      MYENV="$OPTARG"
      ;;
    \? )
      echo "unknown option: $opt"
      exit 1
      ;;
  esac
done
shift $(($OPTIND - 1))


for i in `$ITOPS_HOME/bin/cmtool.pl -a gethosts -env ${MYENV}`; do 
  echo  
  echo -n  "$i  " ;  $ssh $i "/usr/sbin/prtconf  | grep Memory " 2>/dev/null  
done

