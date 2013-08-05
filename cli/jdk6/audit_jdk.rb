#!/usr/bin/env ruby
#
# lwang: This script is to audit JDK6 for an app
#
#
# sample run: for i in `cat ~/junk/z`; do echo =========================== $i; ./audit_jdk.rb -a $i; done
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

  options[:machine] = nil
  opts.on( '-m', '--machine <machine>', 'Machine to check, e.g., esv4-be05.stg' ) do |machine|
    options[:machine] = machine
  end


  options[:env] = nil
  opts.on( '-e', '--env <envname>', 'Env name, e.g., beta. By default: stg' ) do |env|
    options[:env] = env
  end

  opts.on( '-d', '--debug', 'Debug ' ) do
    options[:debug] = true
  end

  opts.on( '-s', '--silent', 'Silent ' ) do
    options[:silent] = true
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
  exit
end


app = options[:app]
env = options[:env] ? options[:env] : 'stg'


puts "App: " + app   if options[:debug]

hosts = `#{itops_home}/bin/cmtool.pl -a get_pool_hosts  -env #{env} -pool #{app} `

if  hosts.empty?
  puts "No host found for app #{app} in env #{env}"
  exit
end


##### if a machine is given, only do on this machine
if options[:machine] 

  installed_dir = MYCM.get_installed_dir(env, app)
  puts "installed dir: " + installed_dir if options[:debug]

  h = options[:machine]

  cmd = %( ssh #{h} ' if [ -e "/export/content/glu/apps/#{installed_dir}" ]; then echo -n 'GLU'; echo -n " ";  ls -1d /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9] ; for p in `cat /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  else echo -n 'non GLU'; echo -n " ";  ls -1d /export/content/#{installed_dir}/i0[0-9][0-9]; for p in `cat /export/content/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  fi' 2>/dev/null )

  unless  options[:silent]
    puts
    print  h + " "
    system( cmd ) 
  end

  ret = `#{cmd} | grep JDK-1_6_0_16`

  if  ret.empty?
    puts "#{app} on #{h} : not JDK6 yet"
  end


  exit
end


hosts.split.each do |h|

  installed_dir = MYCM.get_installed_dir(env, app)
  puts "installed dir: " + installed_dir if options[:debug]

  # for each host, do it
#  cmd = %( ssh #{h} " if [ -e \"/export/content/glu/apps/#{app}\" ]; then grep 'Using java version' /export/content/glu/apps/#{app}/i0[0-9][0-9]/logs/*.log /export/content/glu/apps/#{app}/i0[0-9][0-9]/logs/*.out ; else grep 'Using java version'  /export/content/#{app}/i0[0-9][0-9]/logs/*.log /export/content/#{app}/i0[0-9][0-9]/logs/*.out   ;fi" 2>/dev/null )

#  cmd = %( ssh #{h} ' if [ -e "/export/content/glu/apps/#{app}" ]; then echo 'GLU'; echo "/export/content/glu/apps/#{app}"; for p in `cat /export/content/glu/apps/#{app}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do echo  \$p ; done;  else echo 'non GLU'; echo " /export/content/#{app}";  fi' 2>/dev/null )

#  cmd = %( ssh #{h} ' if [ -e "/export/content/glu/apps/#{app}" ]; then echo -n 'GLU'; echo -n " ";  ls -1d /export/content/glu/apps/#{app}/i0[0-9][0-9] ; for p in `cat /export/content/glu/apps/#{app}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  else echo -n 'non GLU'; echo -n " ";  ls -1d /export/content/#{app}/i0[0-9][0-9]; for p in `cat /export/content/#{app}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  fi' 2>/dev/null )

###  cmd = %( ssh #{h} ' if [ -e "/export/content/glu/apps/#{installed_dir}" ]; then echo -n 'GLU'; echo -n " ";  ls -1d /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9] ; for p in `cat /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  else echo -n 'non GLU'; echo -n " ";  ls -1d /export/content/#{installed_dir}/i0[0-9][0-9]; for p in `cat /export/content/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  fi' 2>/dev/null )


  cmd = %( ssh #{h} ' if [ -e "/export/content/glu/apps/#{installed_dir}" ]; then echo -n 'GLU'; echo -n " ";  ls -1d /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9] ; for p in `cat /export/content/glu/apps/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  else echo -n 'non GLU'; echo -n " ";  ls -1d /export/content/#{installed_dir}/i0[0-9][0-9]; for p in `cat /export/content/#{installed_dir}/i0[0-9][0-9]/logs/*.pid | sed 's/PID=//' `; do ps -efa|grep java | grep \$p ; done;  fi' 2>/dev/null )

  unless  options[:silent]
    puts
    print  h + " "
    system( cmd ) 
  end

  ret = `#{cmd} | grep JDK-1_6_0_16`

  if  ret.empty?
    puts "#{app} on #{h} : not JDK6 yet"
  end

end

#puts


exit


