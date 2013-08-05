#!/usr/bin/python26


import sys
import os
import subprocess
from optparse import OptionParser



def run_cmd( cmd, debug=True):
  if debug:
    print "running cmd: " + cmd
  try:
    retcode = subprocess.call( " %s " % cmd, shell=True )
    if retcode < 0:
      print >>sys.stderr, "Child was terminated by signal", -retcode
  except OSError, e:
    print >>sys.stderr, "Execution failed: ", e



def get_parser():
  usage = "usage: %prog [options] "
  parser = OptionParser(usage)
#  parser.add_option("-f", "--file", dest="filename",
#                        help="read data from FILENAME which contains on each line a ccs app name, e.g., oms, webtrack, peopleSearchService etc.")
#  parser.add_option("-s", "--service", dest="service",
#            help="Service name, e.g., auth-server")
  parser.add_option("-v", "--verbose",
                      action="store_true", dest="verbose",
            help="In verbose mode (not implemented yet)")
  parser.add_option("-d", "--debug",
                      action="store_true", dest="debug",
            help="In debug mode")

  return parser


def get_output_from_cmd( cmd, str=False ):
  p = subprocess.Popen([ cmd ], shell=True, bufsize=0, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)
  out = p.communicate()[0]
  if not out.split() == None:
    if not str:
      return out.split()
    else:
      return out
  else:
    return None


def doit_for( svc ):
  print "---------------- %s " % svc
  all_nodes_ech3 = get_output_from_cmd( "glulist -e ech3 -s %s" % svc )
  all_nodes_ela4 = get_output_from_cmd( "glulist -e ela4 -s %s" % svc )

  sum = 0
  for node in all_nodes_ech3:
    cmd = """ssh -o ConnectTimeout=10 %s '/usr/sbin/prtconf | /bin/egrep "cpu[,| (]" | wc -l ' 2>/dev/null """ % node
    num = get_output_from_cmd( cmd, str=True )
    print "    %s : %s" % ( node, num.strip() )
    if num:
      sum += int(num)

  print "    ", len(all_nodes_ech3), sum

  print "    ~~~~~~~~~~~~~~"
  sum = 0
  for node in all_nodes_ela4:
    cmd = """ssh -o ConnectTimeout=10 %s '/usr/sbin/prtconf | /bin/egrep "cpu[,| (]" | wc -l ' 2>/dev/null """ % node
    num = get_output_from_cmd( cmd, str=True )
    print "    %s : %s" % ( node, num.strip() )
    if num:
      sum += int(num)

  print "    ", len(all_nodes_ela4), sum
  print


########## main()
def main():
  parser = get_parser()
  options, args = parser.parse_args()

  all_services = []
  if sys.argv[1:]:
    all_services = [ i for i in sys.argv[1:] ]
  else:
    all_services_ech3 =  get_output_from_cmd( "glulist -e ech3" )
    all_services_ela4 =  get_output_from_cmd( "glulist -e ela4" )
  
  #  print len(all_services_ech3)
  #  print len(all_services_ela4)
  
    all_services = list( set(all_services_ech3) |  set(all_services_ela4) )

  print "All services:"
  for i in all_services: print i,
  print
  print len(all_services)

  for svc in all_services:
    if svc == 'agent':
      pass
    else:
      doit_for( svc )


if __name__ == "__main__":
    main()
