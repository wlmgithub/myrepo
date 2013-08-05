#!/bin/bash

cd /export/content/leo-tomcat/_i001/logs
/bin/gzcat engine_public_access.log.2010-06-27.gz  | cut -d' ' -f2 | grep -v -- '-' | sort | uniq -c | sort -rn  | head -10
