#!/usr/bin/env ruby
#
# lwang: This script is to audit Tomcat for an app
#
#
#
# needs ITOPS_HOME
itops_home = ENV['ITOPS_HOME']

unless itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end

require 'find'
require 'ftools'
require 'optparse'

$LOAD_PATH.push itops_home+'/lib/ruby'
require 'mycm'

thisprog = __FILE__

def usage ( me )
  puts "usage:  #{me} -h"
  exit
end

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "usage: #{thisprog} <options>  "

  options[:app] = nil
  opts.on( '-a', '--app <appname>', 'Appname to check, e.g., abook' ) do |app|
    options[:app] = app
  end

  options[:env] = nil
  opts.on( '-e', '--env <envname>', 'Env name, e.g., beta. By default: stg' ) do |env|
    options[:env] = env
  end

  opts.on( '-d', '--debug', 'Debug ' ) do
    options[:debug] = true
  end

  opts.on( '-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end
end

optparse.parse!


if options[:debug] 
  puts "Options:"
  puts "app: " + options[:app]
end


unless options[:app]
  puts "I need an app"
  usage ( thisprog )
  exit
end


app = options[:app]
env = options[:env] ? options[:env] : 'stg'


puts "App: " + app   if options[:debug]

unless MYCM.is_frontend?( env, app )
  puts "#{app} is not frontend"
  exit
end


# now that we know app is FE....

hosts = `#{itops_home}/bin/cmtool.pl -a get_pool_hosts  -env #{env} -pool #{app} `

if  hosts.empty?
  puts "No host found for app #{app} in env #{env}"
  exit
end

hosts.split.each do |h|

  installed_dir = MYCM.get_installed_dir(env, app)
  puts "installed dir: " + installed_dir if options[:debug]
  puts
  print  h + " "
  # for each host, do it

#  cmd = %( ssh #{h} ' if [ -e "/export/content/glu/apps/#{installed_dir}" ]; then echo -n 'GLU'; echo -n " ";  ls -1d /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9] ; for p in `cat /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  else echo -n 'non GLU'; echo -n " ";  ls -1d /export/content/#{installed_dir}/i0[0-9][0-9]; for p in `cat /export/content/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  fi' 2>/dev/null )

  cmd = %( ssh #{h} ' cd /export/content/#{installed_dir}/i001/logs; grep -i tomcat catalina.out  | grep "INFO: Starting Servlet Engine:" | tail -1  '  2>/dev/null )

  system( cmd ) 

end

puts


exit


