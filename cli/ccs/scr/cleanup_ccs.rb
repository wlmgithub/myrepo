#!/bin/env ruby
#
# lwang:  cleanup ccs dirs for a given env, leaving the latest 3 dirs
#
require 'optparse'
require 'pp'
require 'rubygems'
require 'highline/import'


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

    options[:ccsdirname] = nil
      opts.on( '-c', '--ccsdirname CCSDIRNAME', 'CCS dir name, e.g., auth rather than auth-server' ) do |ccsdirname|
      options[:ccsdirname] = ccsdirname
    end
 
    options[:env] = nil
      opts.on( '-e', '--env ENV', 'Environment  [required], e.g., ei1, beta, stg, ech3 ' ) do |env|
      options[:env] = env
    end

    options[:execute] = false
    opts.on('-e', '--execute', 'REALLY EXEUTE IT! BE CAREFULL!!!!!!') do
      options[:execute] = true
    end

    options[:file] = nil
      opts.on( '-f', '--file FILE', 'File containing a list of ccs dirs each on a new line' ) do |file|
      options[:file] = file
    end


    options[:debug] = false
    opts.on('-d', '--debug', 'Output debug info') do
      options[:debug] = true
    end
 
  end
  optparse.parse!


  if ( options[:env] == nil )
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
    when 'ei1' then 'esv4-be29.corp'
    when 'ei3' then 'esv4-be44.corp'
  end

end



def get_ccs_root_dir( env=nil )

  warn "I need an env." unless env
  case env
    when 'ech3' then '/export/content/master_repository/PROD-ECH3'
    when 'beta' then '/export/content/repository/STG-BETA'
    when 'stg' then '/export/content/repository/STG-ALPHA'
    when 'ei1' then '/export/content/repository/EI1'
    when 'ei3' then '/export/content/repository/EI3'
  end

end


def get_app_conf_base_uri ( env=nil )

  warn "I need an env." unless env
  case env
    when 'ech3' then 'http://ech3-cfg-vip-a.prod:10093/configuration/get/PROD-ECH3'
    when 'beta' then 'http://esv4-be05.stg:10093/configuration/get/STG-BETA'
    when 'stg' then 'http://esv4-be05.stg:10093/configuration/get/STG-ALPHA'
    when 'ei1' then 'http://esv4-be29.corp:10093/configuration/get/EI1'
    when 'ei3' then 'http://esv4-be44.corp:10093/configuration/get/EI3'
  end

end



def get_ver_stems_of_app( env, ccsdirname,  options ) 

  ccs_host = get_ccs_host( env )

  ccs_root_dir = get_ccs_root_dir( env )

#  cmd_scp = %( /bin/scp worker_for_cleanup.sh #{ccs_host}:~  2>/dev/null)
#  puts "INFO: getting worker over."  if options[:verbose]
#  system( cmd_scp )

  cmd_ssh = %( /bin/ssh #{ccs_host} ' ~/worker_for_cleanup.sh #{ccs_root_dir} #{ccsdirname} ' 2>/dev/null)
  ver_stems = %x( #{cmd_ssh} )

  ver_stems.split("\n")

end


def do_cleanup( sudo, env, ccsdirname, togo_vers,  options )

  togo_vers_str = togo_vers.join(' ')

  if options[:execute]
    puts "INFO: the following vers are cleaned up for #{ccsdirname} in #{env}: -------"
  else
    puts "INFO: the following vers would have been cleaned up for #{ccsdirname} in #{env}: -------"
  end

  puts togo_vers_str

  if options[:execute]

    # DOIT
    ccs_host = get_ccs_host( env )
    ccs_root_dir = get_ccs_root_dir( env )
    cmd_doit = %(  /bin/ssh #{ccs_host} ' #{sudo} ~/worker_for_cleanup.sh #{ccs_root_dir} #{ccsdirname} "#{togo_vers_str}" ' 2>/dev/null)
    system( cmd_doit ) 
    
  end

end


def getpass(prompt)

  pass = ask(prompt) { |q|
    q.echo = '*'
  }
  
  return pass 

end


def warmup_sudo( ssh, ccs_host, sudo, pass, options )

  cmd = %( echo #{pass} | #{ssh} #{ccs_host}  ' #{sudo} ls  /tmp >/dev/null '  )
  puts cmd if options[:debug]
  system( cmd ) if options[:execute]

end


def doit_on(ssh, sudo, ccs_host,  ccsdirname, env, pass, options )

  ver_stems = get_ver_stems_of_app( env, ccsdirname, options )

  sorted_ver_stems = ver_stems.sort_by do |s|
    s.to_i 
  end

  sorted_ver_stems = sorted_ver_stems.select {  |s| s.to_i > 0 }
  limited_rels = ('700' .. '999').to_a

  final_sorted_ver_stems = sorted_ver_stems -   limited_rels

  if options[:debug]
    puts sorted_ver_stems 
    puts '-' * 10
    puts sorted_ver_stems.size
    puts '-' * 10
    puts final_sorted_ver_stems 
    puts '-' * 10
    puts final_sorted_ver_stems.size 

  end

  #
  # keep the latest 3 vers
  #
  togo_vers = []
  while final_sorted_ver_stems.size > 3

    togo = final_sorted_ver_stems.shift
    togo_ver = "0.0.#{togo}"

#    final_sorted_vers = final_sorted_ver_stems.collect{ |s| "0.0.#{s}"  }
    togo_vers << togo_ver

  end

  if togo_vers.size > 0
    do_cleanup( sudo, env, ccsdirname,  togo_vers, options)

  else

    puts "INFO: no cleanup needed for #{ccsdirname} in #{env}"

  end

end


def get_worker_over( env, options )

  ccs_host = get_ccs_host( env )

  ccs_root_dir = get_ccs_root_dir( env )

  cmd_scp = %( /bin/scp worker_for_cleanup.sh #{ccs_host}:~  2>/dev/null)
  puts "INFO: getting worker over."  if options[:verbose]
  system( cmd_scp )

end



def main

  options = get_options()
  
  debug = options[:debug]
  env = options[:env]

  if debug
    puts "env: " + env
  end


  if options[:file] and options[:ccsdirname]
    STDERR.puts "Oops, --file and --ccsdirname are mutually exclusive."
    exit
  end

  ccsdirnames = []

  if options[:file]
    
    unless File.exists? options[:file]
      STDERR.puts "Oops, file does not exists"
      exit
    end

    File.read(  options[:file] ).each_line { |line|
      ccsdirnames << line.chomp!
    }

  elsif options[:ccsdirname]

    ccsdirnames << options[:ccsdirname]

  end


  if debug
    puts "ccsdirnames : " + ccsdirnames.join(' ')
  end

  pass = getpass("Enter your password (kerberos): ")
  
  ssh = '/bin/ssh'
  sudo = '/usr/local/bin/sudo'
  ccs_host = get_ccs_host( env ) 

  warmup_sudo( ssh, ccs_host, sudo, pass, options )

  get_worker_over( env, options )


  ccsdirnames.each { |ccsdirname| 
    puts
    puts "Cleaning up #{ccsdirname} on #{env}"
    puts '-' * 100
    doit_on( ssh, sudo, ccs_host,  ccsdirname, env, pass, options )
  }


end



if $0 == __FILE__
   main()
end




