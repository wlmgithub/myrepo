#!/export/apps/splunk/i001/splunk/bin/python
#
# lwang: This script is to help prepare CCS dirs before a release
#
#
# sample run:
#	rotozip.corp:lwang[654] ~/code/itops/ccs/bin $ ./prepCCS.py   -e  beta   -c  zzzztest  -r R1018
#
import sys
import os
import re
import subprocess
from optparse import OptionParser
from socket import gethostname
import atexit

ssh = '/bin/ssh'
sudo = '/usr/local/bin/sudo'

class Env:
  def __init__(self, name):
    self.name = name

  def get_ccs_host(self):
    if self.name == 'stg' or self.name == 'beta':
#      hostname = gethostname()
      return 'esv4-be05.stg'
    elif self.name == 'ech3':
      return 'ech3-cfg02.prod'
    else:
      return None

  def check_envname_given(self):
    if self.name == 'stg' \
        or self.name == 'beta' \
        or self.name == 'ech3' \
      :
      pass
    else:
      print "ERROR: The environment name you provided ", self.name, " is invalid!"
      sys.exit(1)

  def get_ccs_dir_root(self):
    if self.name == 'stg':
      return '/export/content/repository/STG-ALPHA'
    elif self.name == 'beta':
      return '/export/content/repository/STG-BETA' 
    elif self.name == 'ech3':
      return '/export/content/master_repository/PROD-ECH3'
    else:
      return None


def get_ccs_rel_num( relnum ):
  """
  get ccs_rel_num, e.g., 514 from options.relnum, e.g., R1018
  """
#
# rotozip.corp:lwang[578] /export/content/build.qa.releases/R1018 $ cat LEGACY-MASTER.BOM  | cut -f2 -d'=' | grep '^build'  | cut -f1 -d'_' | sort -u | cut -f2 -d'-'
#  514
#
  # check existence of Rdddd:
  if not os.path.isdir( "/export/content/build.qa.releases/" + relnum):
    print >>sys.stderr, "ERROR: I did not find '/export/content/build.qa.releases/" + relnum + "'"
    sys.exit(1)

  cmd = "cd /export/content/build.qa.releases/; cd %s; cat LEGACY-MASTER.BOM  | cut -f2 -d'=' | grep '^build'  | cut -f1 -d'_' | sort -u | cut -f2 -d'-' " % relnum
  if debug:
    print "cmd: " + cmd

  p = subprocess.Popen([ cmd ], shell=True, bufsize=0, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)
  out = p.communicate()[0]
  if not out.split() == None:
    return ''.join(out.split())
  else:
    return None
 

def get_list_of_limited_rels(ssh,  ccs_host, ccs_dir_root ):
  """
  get a list of limited rels, e.g., 0.0.999
  """
  cmd = "%s %s ' cd  %s; find . -name \"0.0.[987]*\" | sed -e \"s/.*\///\" | sort -u  '  2>/dev/null " % (ssh,  ccs_host, ccs_dir_root )
  if debug:
    print "Running cmd: " + cmd

  p = subprocess.Popen([ cmd ], shell=True, bufsize=0, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)
  out = p.communicate()[0]
  if not out.split() == None:
    return out.split()
  else:
    return None


def get_list_of_rels(ssh,  ccs_host, ccs_dir_root, ccs_app_name ):
  cmd = "%s %s ' ls %s/%s '  2>/dev/null " % (ssh,  ccs_host, ccs_dir_root, ccs_app_name )
  if debug:
    print "cmd: " + cmd

  p = subprocess.Popen([ cmd ], shell=True, bufsize=0, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)
  out = p.communicate()[0]
  if not out.split() == None:
    return out.split()
  else:
    return None


def get_diff_of_list( l1, l2 ):
  """
  get the diff of lists l1 and l2:  l1 - l2
  """
  d = set(l1) - set(l2)
  l = list(d)
  l.sort()
  return l


def get_final_list( list ):
  """ 
  remove non 0.0.xxx items
  """
  final_list = [ item for item in list if '0.0.' in item ]
  return final_list


def copy_last_rel_dir(ssh, ccs_host, ccs_dir_root, ccs_app_name, sudo, last_rel, new_relnum):
  new_rel = '0.0.%s' % new_relnum
  cmd = "%s %s ' cd  %s/%s;  %s cp -rp %s  %s'  2>/dev/null " % (ssh,  ccs_host, ccs_dir_root, ccs_app_name, sudo, last_rel, new_rel )

  if new_rel > last_rel:
    if debug:
      print "Running cmd: " + cmd
    if verbose:
      print "INFO: creating %s from %s for %s in %s on %s." % ( new_rel, last_rel, ccs_app_name, ccs_dir_root, ccs_host)
    run_cmd ( cmd )
  else:
    print >>sys.stderr, "new_rel %s is not greater than last_rel %s for %s. doing no action here." % (new_rel, last_rel, ccs_app_name)
#    sys.exit(1)


def make_new_rel_dir( ssh, ccs_host, ccs_dir_root, ccs_app_name, sudo, new_relnum ):
  if debug:
    print "in make_new_rel_dir()"

  new_rel = '0.0.%s' % new_relnum
  cmd = "%s %s ' cd  %s;  %s mkdir -p %s/%s ;  %s cp /export/home/lwang/bin/empty_extservices_springconfig  %s/%s/extservices.springconfig'  2>/dev/null " % (ssh,  ccs_host, ccs_dir_root, sudo, ccs_app_name, new_rel, sudo, ccs_app_name, new_rel )
  if debug: 
    print "Running cmd: " + cmd
  
  if verbose:
    print "INFO: making %s  for %s in %s on %s." % ( new_rel, ccs_app_name, ccs_dir_root, ccs_host)

  run_cmd ( cmd )


def run_ch_cmds(  ssh, ccs_host, ccs_dir_root, sudo):
  if debug:
    print "running chown and chmod"

  cmd = "%s %s ' cd  %s; %s chown -R cm:app .; %s chmod -R 775 .  ' 2>/dev/null " % ( ssh, ccs_host, ccs_dir_root,  sudo, sudo )
  if debug: 
    print "Running cmd: " + cmd

  run_cmd ( cmd )
  
  
def warmup_sudo( ssh,  ccs_host, sudo ):
  prompt = "Enter password (kerberos): "
  pwd = getpass(prompt)
#  print pwd
  print "\n"
  cmd = "echo %s | %s %s ' %s ls >/dev/null 2>&1 ' 2>/dev/null " % ( pwd, ssh, ccs_host, sudo ) 
  if debug:
    #print "Running cmd: " + cmd
    print "INFO: running warmup_sudo"

  run_cmd( cmd )


def getpass(prompt="Enter password (kerberos): "):
  import termios
  fd = sys.stdin.fileno()
  old = termios.tcgetattr(fd)
  new = termios.tcgetattr(fd)
  new[3] = new[3] & ~termios.ECHO   # lflags
  try:
    termios.tcsetattr(fd, termios.TCSADRAIN, new) 
    passwd = raw_input(prompt)  
  finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old) 
  return passwd


def run_cmd( cmd ):
  if debug:
    print "running cmd: " + cmd
  try:
    retcode = subprocess.call( " %s " % cmd, shell=True )
    if retcode < 0:
      print >>sys.stderr, "Child was terminated by signal", -retcode      
#    else:
#      print >>sys.stderr, "Child returned", retcode      
  except OSError, e:
    print >>sys.stderr, "Execution failed: ", e


def backup_env_level_stuff(ssh,  ccs_host, ccs_dir_root, rel):
  #
  # rel: e.g., R1018
  # for the time being, only env-level extservices.springconfig and injected.properties are backed up to  ENV_backup 
  #
  cmd = "%s %s ' cd  %s;  if [ ! -f ENV_backup/extservices.springconfig.prepccs_bk_pre_%s ]; then %s cp -p extservices.springconfig  ENV_backup/extservices.springconfig.prepccs_bk_pre_%s; fi; if [ ! -f ENV_backup/injected.properties.prepccs_bk_pre_%s ]; then %s cp -p injected.properties ENV_backup/injected.properties.prepccs_bk_pre_%s; fi '  2>/dev/null " % (ssh,  ccs_host, ccs_dir_root, rel, sudo, rel, rel, sudo, rel)
  if debug:
    print "running cmd: " + cmd
    print "INFO: backing up ENV-level extservices.springconfig and injected.properties to %s/ENV_backup on %s. " % ( ccs_dir_root, ccs_host )

  run_cmd( cmd )
  

def doit_for_one(ssh, sudo, ccs_host, ccs_dir_root, ccs_app_name, ccs_rel_num, options_relnum):

  list_of_rels = get_list_of_rels(ssh,  ccs_host, ccs_dir_root, ccs_app_name)
  if len(list_of_rels) == 0:
    print 'I did not find any existing rel numbers for %s... might be a new service.' % ccs_app_name
  else:
    if debug:
      print "list_of_rels: " + str(list_of_rels)


  list_of_limited_rels = get_list_of_limited_rels(ssh,  ccs_host, ccs_dir_root )
  if debug:
    print "list_of_limited_rels: " + str(list_of_limited_rels )

  list_of_rels_diff = get_diff_of_list( list_of_rels, list_of_limited_rels )
  if debug:
    print "list_of_rels_diff: " + str(list_of_rels_diff)

  list_of_rels_final = get_final_list( list_of_rels_diff )
  if debug:
    print "list_of_rels_final: " + str(list_of_rels_final)



  if  len(list_of_rels_final) != 0:
    last_rel = list_of_rels_final.pop()
    if last_rel != None:
      if debug:
        print "last rel: " + last_rel
        print "copy last_rel dir to the new dir"
      copy_last_rel_dir( ssh,  ccs_host, ccs_dir_root, ccs_app_name, sudo, last_rel, ccs_rel_num )
  else:
    print "Again, I did not find any existing rel number..."
    reply = raw_input("Is this a new service? (y/n)")
    if reply.startswith('y'):
      # it's a new service, let's make a new one
      make_new_rel_dir(  ssh, ccs_host, ccs_dir_root, ccs_app_name, sudo, ccs_rel_num )

    else:
      print "You said it's not a new service, but I found no rel dir like 0.0.xxx for it. weird. quit."
      sys.exit(1)
    
  backup_env_level_stuff(ssh,  ccs_host, ccs_dir_root, options_relnum)



########## main()
def main():
  usage = "usage: %prog [options] "
  parser = OptionParser(usage)
  parser.add_option("-e", "--env", dest="envname",
			help="[required] Environment name provided. supported ones: stg, beta, ech3")
  parser.add_option("-f", "--file", dest="filename",
			help="read data from FILENAME which contains on each line a ccs app name, e.g., oms, webtrack, peopleSearchService etc.")
  parser.add_option("-c", "--ccsapp", dest="ccsappname",
			help="[required] The directory name in CCS  provided, e.g., should use auth rather than auth-server")
  parser.add_option("-r", "--rel", dest="relnum",
			help="[required] RELNUM provided, e.g., R1018,  NOTE: the script will find out the CCS dir num automatically, e.g., 514")
  parser.add_option("-v", "--verbose",
                      action="store_true", dest="verbose",
			help="In verbose mode")
  parser.add_option("-q", "--quiet",
                      action="store_false", dest="verbose",
			help="In quiet mode")
  parser.add_option("-d", "--debug",
                      action="store_true", dest="debug",
			help="In debug mode")

  (options, args) = parser.parse_args()

  # make global
  global debug
  debug = options.debug

  global verbose
  verbose = options.verbose

  # should only be run on rotozip
  hostname = gethostname()
  if hostname != 'rotozip.corp':
    print >>sys.stderr, "ERROR: run the script on rotozip."
    sys.exit(1)

  if options.filename and options.ccsappname:
    print >>sys.stderr, "ERROR: -c and -f are mutually exclusive."
    parser.print_help()
    sys.exit(1)
    
  # required:  options.envname
  if options.envname == None:
    print "ERROR: I need an envname, e.g., beta"
    parser.print_help()
    sys.exit(1)

  # required:  options.ccsappname
#  if options.ccsappname == None:
#    print "ERROR: I need an CCSAPPNAME, e.g., auth"
#    parser.print_help()
#    sys.exit(1)

  # required: options.relnum
  if options.relnum == None:
    print "ERROR: I need a RELNUM, e.g., R1018 "
    parser.print_help()
    sys.exit(1)

  list_of_ccsappnames = []
  if options.filename:
    try:
      fh = open(options.filename, "r")
      for line in fh:
        if line.strip():
          list_of_ccsappnames.append( line.strip() )
    except IOError:
      print >>sys.stderr, "ERROR: File %s does not exist!" % options.filename
  elif options.ccsappname:
    list_of_ccsappnames.append( options.ccsappname )

  # validate options.relnum: Rdddd
  r = re.compile('^R\d{4}$')
  if not re.match(r, options.relnum):
    print >>sys.stderr, "ERROR: required format for -r: Rdddd. i.e., R followed by 4 digits."
    sys.exit(1)

  ccs_rel_num = get_ccs_rel_num(options.relnum)

  env = Env(options.envname) 
  env.check_envname_given()
  ccs_host = env.get_ccs_host()
  ccs_dir_root =  env.get_ccs_dir_root()
  if ccs_host == None or ccs_dir_root == None:
    print "ERROR: I did not find ccs_host or ccs_dir_root."
    sys.exit(1)

  if options.debug:
    print "ccs_host: " +  ccs_host
    print "ccs_dir_root: " +  ccs_dir_root 
    print "ccs_rel_num: " +   ccs_rel_num


  ########## now that the prep is done, let's do the real work
  warmup_sudo(  ssh,  ccs_host, sudo )

  for ccs_app_name in list_of_ccsappnames:
    if options.debug:
      print "ccs_app_name: " +  ccs_app_name
    if options.verbose:
      print "Processing %s..." % ccs_app_name
    options_relnum = options.relnum 
    doit_for_one(ssh, sudo,  ccs_host, ccs_dir_root, ccs_app_name, ccs_rel_num, options_relnum)
    print 
  
  atexit.register(run_ch_cmds,  ssh, ccs_host, ccs_dir_root, sudo )

  # we are done here
  sys.exit(0)


if __name__ == "__main__":
    main()

