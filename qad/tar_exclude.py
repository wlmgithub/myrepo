#!/usr/bin/env python

import os
import tarfile

def excluded_files(filename):
  if ".svn" in filename:
    return True

tar = tarfile.open('test.tar','w')
tar.add(os.getcwd(), exclude=excluded_files)
tar.close()
