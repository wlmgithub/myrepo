#!/bin/bash

vernum=${1:?"i need an version number, e.g., 1110"}

# make sure vernum is a number
if [ $vernum -eq $vernum 2> /dev/null ]; then
  echo "$vernum is a number"
else
  echo "$vernum isn't a number"
  exit
fi 
