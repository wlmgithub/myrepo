#!/export/apps/splunk/i001/splunk/bin/python
#
# lwang: generate port 
#
#
#  ssh esv4-be05.stg ' ./ff  beta '
#
# which app has duplicated lines:
#	./gen.py -v -e beta | cut -f1 -d: | cut -f1 -d/ | sed 's/ $//' | uniq -d
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

ssh = '/bin/ssh'
scp = '/bin/scp'
worker_scr = './port_worker.pl'

def getoptions():
  usage = "usage: %prog [options] "
  parser = OptionParser(usage)
  parser.add_option(    "-e", "--env", dest="env",
                        help="[required] Environment name")
  parser.add_option(    "-v", "--verbose",
                        action="store_true", dest="verbose",
                        help="In verbose mode")
  parser.add_option(    "-d", "--debug",
                        action="store_true", dest="debug",
                        help="In debug mode")
  parser.add_option(    "-p", "--publish",
                        action="store_true", dest="publish",
                        help="Publish the port result to htdocs")



  (options, args) = parser.parse_args()

  # required:  options.env
  if options.env == None:
    print "ERROR: I need env name, e.g., stg, beta, ech3, ei"
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

  # xfer worker_scr
  cmd = "%s %s %s:~ 2>/dev/null" % ( scp, worker_scr, ccs_host)
  mycm.run_cmd( cmd, debug=None)
  
  # do work
  cmd = "%s %s '~/%s %s' 2>/dev/null " % ( ssh, ccs_host, worker_scr, env)
  ret = mycm.run_cmd_and_return( cmd, debug=None )
  
  if options.verbose:
    print ret,

  # publish if needed
  if options.publish:
    if options.verbose:
      print "publishing..."

# mv stg beta ech3 /export/content/http/i001/htdocs/cm/glu/port
    pub_dir = '/export/content/http/i001/htdocs/cm/glu/port'
    filename = 'gen_port_' + env
    if options.debug:
      print "full path to pub_dir filename : " + pub_dir + '/' +  filename
    f = open(pub_dir + '/' +  filename, 'w')
    f.write(ret)
    f.close()

    # if 'I' own the file
    if pwd.getpwuid(os.getuid())[0] == pwd.getpwuid(os.stat( os.path.join(pub_dir, filename) ).st_uid).pw_name:
      # make it publish-able by all
      os.chmod(pub_dir + '/' +  filename, stat.S_IRWXU | stat.S_IRWXO | stat.S_IRWXG)

  else:
    if options.debug:
      print "not publishing"

if __name__ == '__main__':
  main()
