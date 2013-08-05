#!/export/apps/splunk/i001/splunk/bin/python
#
# lwang: check availability of a port
#
#  	based on gen.py
#
import sys
import os, stat
import socket
import subprocess
import pprint
from optparse import OptionParser
sys.path.append(os.environ['ITOPS_HOME'] + '/lib/python')
import mycm
import pwd
import re
import sets

ssh = '/bin/ssh'
scp = '/bin/scp'
worker_scr = './port_worker.pl'

def getoptions():
  usage = "usage: %prog [options] "
  parser = OptionParser(usage)
  parser.add_option(    "-e", "--env", dest="env",
                        help="[required] Environment name")
  parser.add_option(    "-p", "--portv", dest="port",
                        help="[required] Port number to check")
  parser.add_option(    "-v", "--verbose",
                        action="store_true", dest="verbose",
                        help="In verbose mode")
  parser.add_option(    "-d", "--debug",
                        action="store_true", dest="debug",
                        help="In debug mode")


  (options, args) = parser.parse_args()

  # required:  options.env
  if options.env == None:
    print "ERROR: I need env name, e.g., stg, beta, ech3, ei"
    parser.print_help()
    sys.exit(1)

  # required:  options.port
  if options.port == None:
    print "ERROR: I need a port number to check" 
    parser.print_help()
    sys.exit(1)

  return (options, args)

def main():
  (options, args) = getoptions()
  
  env =  options.env
  if env == 'stg' or env == 'beta':
    ccs_host = 'esv4-be05.stg'
  elif env == 'ech3':
    ccs_host = 'ech3-cfg02.prod'
  elif env == 'ei':
    ccs_host = 'eiadmin@ei1-app2-zone4.qa'
  else:
    print "ERROR: env %s not allowed. Supported env: stg, beta, ech3, ei" % env
    sys.exit(1)

#  print 'env = ' + env
#  print 'ccs_host = ' + ccs_host

  print "Checking availability of port %s in environment %s......" %  (options.port, env)

  # xfer worker_scr
  cmd = "%s %s %s:~ 2>/dev/null" % ( scp, worker_scr, ccs_host)
  mycm.run_cmd( cmd, debug=None)
  
  # do work
  cmd = "%s %s '~/%s %s' 2>/dev/null " % ( ssh, ccs_host, worker_scr, env)
  ret = mycm.run_cmd_and_return( cmd, debug=None )
  
  ret_list = ret.split('\n')

  if options.debug:
    print type(ret_list)
    print ret


  all_ports = get_all_ports( ret_list )

  all_ports_uniq =  uniq(all_ports)
  all_ports_uniq.sort()

  if options.verbose:
    print "\nAll used ports:"
    print ' '.join(all_ports_uniq)
    
  if options.port in uniq(all_ports):
    print "port %s is already used." % options.port
  else:
    print "port %s is available." % options.port


def get_all_ports(seq):
  all_ports = []
  for item in seq:
    #print item
    m = re.match(r'.*: (.*)', item)
    if m:
      port = m.group(1)
      if port != None and port != '':
        #print port
        all_ports.append( port ) 
  return all_ports


def uniq(seq):
  # not order preserving
  set = sets.Set(seq)
  return list(set)

# people-search/esv4-be77/i013 : 10163


if __name__ == '__main__':
  main()
