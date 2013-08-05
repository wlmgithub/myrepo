#!/bin/bash

MERGE_URL='svn+ssh://svn.corp.foobar.com/secure/siteops/ccs/branches'

function askme {

  while true; do 
    read -p "Do you want to continue? (y/n)" yn
    case $yn in
      [Yy]* )  break;;
      [Nn]* )  exit;;
      *     ) echo "Please answer yes or no";;
    esac
  done

}


function domerge {

  cd ~/src

  FROM=$1
  TO=$2

  echo
  echo ========================= 
  echo "$FROM -> $TO"

  cd $TO
  pwd
  echo

  svn st
  svn up

  echo
  echo "---------------------------------"
  echo "running dry-run $FROM -> $TO"
  svn merge $MERGE_URL/$FROM --dry-run

  echo
  echo "---------------------------------"
  echo "about to do real merge $FROM -> $TO"
  askme
  svn merge $MERGE_URL/$FROM 

  echo 
  echo "---------------------------------"
  echo "about to checkin for  merge $FROM -> $TO"
  askme
  svn ci -m "merged $FROM to $TO" 
  

}




######################################## STG

domerge  CONFIG_R1128  CONFIG_R1130

domerge  CONFIG_R1130  CONFIG_TRUNK

######################################## PROD

domerge PROD_R1128  PROD_TRUNK

