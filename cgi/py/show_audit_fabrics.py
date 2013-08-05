#!/bin/python
from __future__ import with_statement
import cgi
import cgitb
import os
import time


# globals, yucky
FS_DIR = '/export/content/http/i001/htdocs/cm/audit_fabrics'
ALL_ENVS = [ 'ei1', 'ei3', 'stg', 'beta', 'ech3', 'ela4' ]

def get_dirnames( dir ):
  d = os.listdir( dir )  
  return d

def _1_get_data( app, env ):
  fn = os.path.join( FS_DIR, app, env, 'res.txt' )
  data = ''
  with open( fn ) as fh:
    for line in fh:
      if line:
        data += line
  return data 


def get_data( app, env ):
  fn = os.path.join( FS_DIR, app, env, 'res.txt' )
  data = [] 
  if not os.path.isfile( fn ):
    return None
  with open( fn ) as fh:
    for line in fh:
      if line:
        s = line.replace('GLU', '&nbsp; &nbsp;GLU &nbsp; &nbsp; ').split()[1:]
        data += s + [ '<br>' ]
  return  ''.join( data )

def get_last_modified( app, env ):
  app_dir = os.path.join( FS_DIR, app )
  last_modified = os.path.getmtime( app_dir )
  return time.strftime("%Y-%m-%d %I:%M:%S %p", time.localtime(last_modified))

def display_data_header( envs ):
  arr = [ 'app' ]
  arr += envs
  arr += [ 'last updated' ]
  t_arr = tuple( arr )
  print """
  <table border='2'> 
  <tr bgcolor='green'>
  <th> %s </th> 
  <th> %s </th>
  <th> %s </th>
  <th> %s </th>
  <th> %s </th>
  <th> %s </th>
  <th> %s </th>
  <th> %s </th>
  </tr>
  """ %  t_arr


def display_data_footer():
  print """
  </table>  
  """


def display_data(  data ):
  apps = data.keys()
  apps.sort()
  for app in apps:
    env_show = []
    last_modified = ''
    html = ' <td> %s </td> ' % app
    for item in data[app]:
      for env in ALL_ENVS:
        h = item[0]
        if env in h:
          last_modified = get_last_modified( app, env )
          html += '<td> %s </td> ' % h[env]
          if not env in env_show:
            env_show.append( env )
    html += '<td> %s </td>' % last_modified
    html += '</tr>'

    version_match = get_version_match( app )
    html_show = None
    if version_match:
      html_show  = '<tr>' + html
    else:
      html_show  = '<tr bgcolor="red">' + html
  
    print  html_show


def get_version_match( app ):
  """ parse each file in the app dir and gather version match indicator: True / False
  """
  app_dir = os.path.join( FS_DIR, app )
  res_files = []
  for env in ALL_ENVS:
    res_files.append( os.path.join( app_dir, env, 'res.txt' )  )
  
  version_match = True    # make True the default
  ref_ver = ''  # reference version string 
  for file in res_files:
    if not os.path.isfile( file ):
      version_match = False
      break
    with open( file, 'r' ) as fh:
      # case 1: file only has blanks
      lines = [ l for l in fh.readlines() if l.strip() ]
      if not lines:
        version_match =  False
        break
      # case 2: any version mismatch
      #         this part may be revisited when multiple instances are encountered
      #         i.e., with ixxx at the end of each line
      for line in lines:
        ver = line.split()[-1]
        if not ref_ver:
          ref_ver = ver
        else:
          if not ref_ver == ver:
            version_match = False
            break

      
  return version_match





def main():
  print "Content-type: text/html"     # HTML is following
  print                               # blank line, end of headers
  
  print "<h1>Showing Fabric Audit Results </h1>"
  print "<a href='http://rotozip.corp.foobar.com/cm/doc/audit_fabrics/README' target='_blank'> how to update this page  </a> "
  print "<p>"
  
  form = cgi.FieldStorage()
  
  for i in form:
    print "<p>%s : %s <p>\n" %  ( i, form[i].value )
  
  all_apps = get_dirnames( FS_DIR )

#  print all_apps

  for app in all_apps:
    app_dir = os.path.join( FS_DIR, app )
    all_envs = get_dirnames( app_dir )
#    print all_envs

  # sort all_envs
  all_envs.sort()

  # data is a hash of lists: app -> [ { env -> content } ]
  data = {}
  for app in all_apps:
    data[app] = []
    for env in all_envs:
      data[app].append([{ env :  get_data( app, env ) }])

  display_data_header( all_envs  )

  display_data( data )

  display_data_footer()

if __name__ == '__main__':
    main()
