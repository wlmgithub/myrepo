#!/bin/bash

if [ ! -e "/Volumes/Staff" ]; then
  echo "Mounting /Volumes/Staff, use LDAP password!"
  mkdir -p /Volumes/Staff
  mount_smbfs   //lwang@dfs.foobar.biz/Staff /Volumes/Staff
fi
