#!/bin/env ruby
#
# lwang: get latest ccs ver(s) for a given env and a given ccsdir
#
#   requires: find_latest_ver.pl  in this dir
#
require 'optparse'

# needs ITOPS_HOME
$itops_home = ENV['ITOPS_HOME']

unless $itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end


def get_options()

  options = {}

  optparse = OptionParser.new do |opts|

    opts.banner = "usage: " + __FILE__ + " [options] "


    opts.on( '-h', '--help', 'Display help screen') do
      puts opts
      exit
    end

    options[:verbose] = false
    opts.on('-v', '--verbose', 'Output more info') do
      options[:verbose] = true
    end

    options[:ccsdir] = nil
      opts.on( '-c', '--ccsdir CCSDIR', 'CCSDIR name, e.g., auth' ) do |ccsdir|
      options[:ccsdir] = ccsdir
    end

    options[:debug] = false
    opts.on('-d', '--debug', 'Output debug info') do
      options[:debug] = true
    end

    options[:env] = nil
      opts.on( '-e', '--env ENV', 'Environment [required], e.g., ei1, beta, stg, ech3 ' ) do |env|
      options[:env] = env
    end

  end
  optparse.parse!


  if options[:env] == nil
    puts optparse.help()
    exit
  end


  options 

end


def get_ccs_host( env=nil )

  warn "I need an env." unless env
  case env
    when 'beta', 'stg'  then 'esv4-be05.stg'
    when 'ech3' then 'ech3-cfg02.prod'
    when 'ela4' then 'ela4-glu02.prod'
    when 'ei1' then 'esv4-be29.corp'
    when 'ei3' then 'esv4-be44.corp'
  end

end



def get_ccs_root_dir( env=nil )

  warn "I need an env." unless env
  case env
    when 'ech3' then '/export/content/master_repository/PROD-ECH3'
    when 'ela4' then '/export/content/master_repository/PROD-ELA4'
    when 'beta' then '/export/content/repository/STG-BETA'
    when 'stg' then '/export/content/repository/STG-ALPHA'
    when 'ei1' then '/export/content/repository/EI1'
    when 'ei3' then '/export/content/repository/EI3'
  end

end



def get_latest_ver( env1, ccsdir, options ) 

  ccs_host = get_ccs_host( env1 )

  ccs_root_dir = get_ccs_root_dir( env1 )

  cmd_scp = %( /bin/scp #{$itops_home}/ccs/scr/find_latest_ver.pl  #{ccs_host}:~  2>/dev/null)
  puts "INFO: getting find_latest_ver.pl  over."  if options[:verbose]
  puts "DEBUG: running #{cmd_scp}" if options[:debug]
  system( cmd_scp )

  unless ccsdir == nil
    cmd_ssh = %( /bin/ssh #{ccs_host} ' ~/find_latest_ver.pl  #{ccs_root_dir} #{ccsdir}; /bin/rm ~/find_latest_ver.pl   ' 2>/dev/null)
  else
    cmd_ssh = %( /bin/ssh #{ccs_host} ' ~/find_latest_ver.pl  #{ccs_root_dir} ; /bin/rm ~/find_latest_ver.pl   ' 2>/dev/null)
  end

  puts "DEBUG: running #{cmd_ssh}" if options[:debug]
  apps = %x( #{cmd_ssh} )

  puts apps
   #apps.class = String
#  apps.split("\n")

end


def main

  options = get_options()
  
  env = options[:env]
  ccsdir = options[:ccsdir]

  if options[:debug] 
  
    puts "env: " + env
    puts "ccsdir: " + ccsdir

  end

  get_latest_ver( env, ccsdir, options )
#  apps_with_given_ver = get_latest_ver( env, ccsdir, options )

#  puts apps_with_given_ver 

end


if $0 == __FILE__
  main()
end

exit


