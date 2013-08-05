#!/bin/bash
# 
#  ./worker.sh /export/content/repository/STG-BETA 520
#
root_dir=$1
ver=$2
cd $root_dir
find . -type d -name 0.0.$ver | sed -e 's/\/0.0.*//' -e 's/\.\///' | sort -u
