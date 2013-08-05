import re
import subprocess

class MYCM(object):
  def __init__(self, env):
    self.env = env

  def get_ccs_rel(self, env, release):
    pass    

def get_build_dir(appname=None, relname=None):
  ''' given an appname,e.g., auth-server, and a release name, e.g., R1020, 
      find the corresponding build dir name
  '''
  build_dir_root = '/export/content/build.qa.releases'
  legacy_master_file = build_dir_root + '/' + relname + '/' + 'LEGACY-MASTER.BOM'
  for line in open( legacy_master_file ):
    m = re.match(r'%s=(.*)' % appname, line)
    if m:
      return m.group(1)
  else:
      return None
    

def get_warname(appname=None, relname=None):
  build_dir_root = '/export/content/build.qa.releases'
  build_bom_file = build_dir_root + '/' + relname + '/' + 'BUILD.BOM'
  for line in open ( build_bom_file ):
    m = re.match(r'(.*)=\b%s\n' % appname, line)
    if m:
      return m.group(1)
  else:
    return None


def get_ccs_dirname(appname=None, relname=None):
  ''' given an appname,e.g., auth-server, and a release name, e.g., R1020, 
      find the correspondig ccs_dirname

      this has to be run on rotozip

  '''
  build_dir_root = '/export/content/build.qa.releases'
  warname = get_warname(appname, relname)
  build_dir = get_build_dir(appname, relname)

  config_properties_file = build_dir_root + '/' + relname + '/' +  build_dir + '/' + warname + '/' + 'exploded-war/META-INF/config.properties'

  for line in open( config_properties_file ):
    m = re.match(r'^com.foobar.app.name=(.*)', line)
    if m:
      return m.group(1)
  else:
    return None



def run_cmd_and_return( cmd=None, debug=None ):
  p = subprocess.Popen([ cmd ], shell=True, bufsize=0, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)
  out = p.communicate()[0]
  if not out.split() == None:
    return out
#    return out.split()
  else:
    return None


def run_cmd( cmd=None, debug=None ):
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


def main():
  tuple_of_apps = ('auth-server', 'cap', 'sam-server')
  rel = 'R1020'
  for a in tuple_of_apps:
    print '%s : %s : %s : %s'  % (a, get_build_dir(a, rel), get_warname(a, rel), get_ccs_dirname(a, rel) )

  run_cmd( 'ls', debug=None )

if __name__ == '__main__':
  main()
