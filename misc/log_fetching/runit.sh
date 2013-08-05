#!/bin/bash

# time ./fetcher.pl -file ./haris_comps  -start '2009/11/05 06:00' -end '2009/11/05 09:00' -d  -execute

# time ./fetcher.pl -env ech3 -app all -start '2009/11/10 07:00' -end '2009/11/10 09:00' -d -execute 


YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`

TODAY="$YEAR/$MONTH/$DAY"

#echo $TODAY

ENV=${1:?"I need an env, e.g., ech3, stg"}
APP=${2:?"I need an app, e.g., auth-server, all"}
START_MINUTE=${3:?"I need a start minute string, e.g., 06:00"}
END_MINUTE=${4:?"I need an end minute string, e.g., 09:00"}

START="$TODAY $START_MINUTE"
END="$TODAY $END_MINUTE"

#echo "$START"
#echo "$END"

#CMD="./fetcher.pl -file ./haris_comps  -start '$START' -end '$END' -d -execute"
CMD="./fetcher.pl -env $ENV -app $APP -start '$START' -end '$END' -d -execute"

echo $CMD

#$CMD
