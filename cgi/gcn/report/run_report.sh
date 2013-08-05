#!/bin/bash

cd /export/home/lwang/gcn_report
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/mysql/lib


usage() 
{
  cat <<EOM;

  $0 [ -h ] [ -s '<comma_separated_recipients>' ] <start> <end>

e.g.,

  $0 '2010-08-07' '2010-08-15'
	: this will run report from 2010-08-07 to 2010-08-15

  $0 
	: this will run report from <seven days ago> to today

  $0 -s 'lwang@foobar.com,nocstaff@foobar.com' 
	: this will run report from <seven days ago> to today, and send report to the list specified

  $0 -s 'gcn-report@linedin.com'  '2010-08-07' '2010-08-15'
	: this will run report from 2010-08-07 to 2010-08-15, and send report to gcn-report 


EOM
} 

while getopts "hs:" opt; do
  case $opt in
    h ) 
      usage
      exit 0
      ;;
    s ) 
      sendto="$OPTARG"
      ;;
     \? )
      echo "unknown option: $opt"
      exit
      ;;
  esac
done
shift $(($OPTIND - 1 ))

if [ -n "$1" ]; then
  start=$1
fi

if [ -n "$2" ]; then
  end=$2
fi

start=$1
end=$2

#echo "start: $start"
#echo "end: $end"
#echo "sendto: $sendto"

if [ -n "$1" -a  -n "$2" ]; then
  echo "Running report from $start to $end"
  if [ -n "$sendto" ]; then
    ./report.pl --start "$start"  --end "$end"  --sendto "$sendto"
  else
    ./report.pl --start "$start"  --end "$end"
  fi
fi

if [ -z "$1" -a -z "$2" ]; then
  echo "Running report from seven days ago to today"
  if [ -n "$sendto" ]; then
    ./report.pl --sendto "$sendto" 
  else
    ./report.pl
  fi
fi

