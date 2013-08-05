"""
 lwang: parse json with python
"""
import sys
import re
import subprocess
import simplejson as json

p = subprocess.Popen( [ 'glu -f stg-beta status'  ] ,  shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

out, err  = p.communicate()

print out

### blob is a json string in the format as follows
blob = json.loads(out)

#print type(blob['entries'])

for o in blob['entries']:

  print '*' * 80 
  print  o['metadata']['container']['name'], o['agent'], 
  print

  wars_str = o['initParameters']['wars']
  wars_ary = wars_str.split('|')
  for w in wars_ary:
    for m in re.finditer(r"ivy:.*/(.*(?:-STG-BETA)?)/(.*)", w):
      war = m.group(1)
      ver = m.group(2)
      print "\t%s %s" % ( war, ver )
  
#  print o['agent'],  o['metadata']['container']['name']


######################################
sys.exit()


{
  "entries": [
    {
      "agent": "esv4-admin02.stg.foobar.com",
      "initParameters": {
        "config": "ivy:/com.foobar.network.config.container/agent-STG-BETA/0.0.1126-RC2.7079",
        "skeleton": "ivy:/com.foobar.network.container/container-jetty/0.0.1120-RC4.6428",
        "wars": "ivy:/com.foobar.network.agent/agent-war/0.0.1120-RC1.5988|agent|ivy:/com.foobar.network.config.app/agent-war-STG-BETA/0.0.1126-RC2.7079"
      },
      "metadata": {
        "container": {
          "kind": "servlet",
          "name": "agent"
        },
        "drMode": "primary",
        "product": "network",
        "version": "R1128"
      },
      "mountPoint": "/agent/i001",
      "script": "ivy:/com.foobar.glu.glu-scripts/glu-scripts-jetty/3.3.0/script",
      "tags": ["backend"]
    },
    {
      "agent": "esv4-app0025.stg.foobar.com",
      "initParameters": {
        "skeleton": "ivy:/com.foobar.network.container/container-jetty/0.0.990-RC1.4601",
        "wars": "ivy:/com.foobar.network.cloud/cloud-war/0.0.1106-RC2.4672|cloud"
      },
      "metadata": {
        "container": {
          "kind": "servlet",
          "name": "cloud"
        },
        "drMode": "primary",
        "product": "network",
        "version": "R1128"
      },
      "mountPoint": "/cloud/i001",
      "script": "ivy:/com.foobar.glu.glu-scripts/glu-scripts-jetty/3.3.0/script",
      "tags": [
        "backend",
        "databus1-client"
      ]
    },
    {
      "agent": "esv4-app11.stg.foobar.com",
      "initParameters": {
        "config": "ivy:/com.foobar.network.config.container/agent-STG-BETA/0.0.1126-RC2.7079",
        "skeleton": "ivy:/com.foobar.network.container/container-jetty/0.0.1120-RC4.6428",
        "wars": "ivy:/com.foobar.network.agent/agent-war/0.0.1120-RC1.5988|agent|ivy:/com.foobar.network.config.app/agent-war-STG-BETA/0.0.1126-RC2.7079"
      },
      "metadata": {
        "container": {
          "kind": "servlet",
          "name": "agent"
        },
        "drMode": "primary",
        "product": "network",
        "version": "R1128"
      },
      "mountPoint": "/agent/i001",
      "script": "ivy:/com.foobar.glu.glu-scripts/glu-scripts-jetty/3.3.0/script",
      "tags": ["backend"]
    },
    {
      "agent": "esv4-app11.stg.foobar.com",
      "initParameters": {
        "config": "ivy:/com.foobar.network.config.container/company-cloud-STG-BETA/0.0.1118-RC2.2374",
        "skeleton": "ivy:/com.foobar.network.container/container-jetty/0.0.990-RC1.4601",
        "wars": "ivy:/com.foobar.network.company/company-cloud-war/0.0.1110-RC1.5085|companyCloud|ivy:/com.foobar.network.config.app/company-cloud-war-STG-BETA/0.0.1118-RC2.6093"
      },
      "metadata": {
        "container": {
          "kind": "servlet",
          "name": "company-cloud"
        },
        "drMode": "primary",
        "product": "network",
        "version": "R1128"
      },
      "mountPoint": "/company-cloud/i001",
      "script": "ivy:/com.foobar.glu.glu-scripts/glu-scripts-jetty/3.3.0/script",
      "tags": [
        "backend",
        "databus1-client"
      ]
    },
    {
      "agent": "esv4-rdb04.stg.foobar.com",
      "initParameters": {
        "config": "ivy:/com.foobar.network.config.container/repdb-server-STG-BETA/0.0.1120-RC2.6340",
        "skeleton": "ivy:/com.foobar.network.container/container-jetty/0.0.990-RC1.4601",
        "wars": "ivy:/com.foobar.network.repdb/repdb-war/0.0.1118-RC2.6177|repdb|ivy:/com.foobar.network.config.app/repdb-war-STG-BETA/0.0.1120-RC2.6340"
      },
      "metadata": {
        "container": {
          "kind": "servlet",
          "name": "repdb-server"
        },
        "drMode": "primary",
        "product": "network",
        "version": "R1128"
      },
      "mountPoint": "/repdb-server/i001",
      "script": "ivy:/com.foobar.glu.glu-scripts/glu-scripts-jetty/3.3.0/script",
      "tags": [
        "backend",
        "databus1-client"
      ]
    }
  ],
}

