#!/bin/env ruby
#
# lwang: This script is used to "process" gc log
#
#

# needs ITOPS_HOME
itops_home = ENV['ITOPS_HOME']

unless itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end

$LOAD_PATH.push itops_home+'/lib/ruby'
require 'mycm'

require 'optparse'
require 'enumerator'

THIS_PROG = __FILE__

#puts ARGV
#puts ARGV.class
#exit

$today =  Time.now.localtime.strftime("%Y-%m-%d")  # -> 2010-03-05


options = {}
optparse = OptionParser.new do |opts|

  opts.banner = "usage: #{THIS_PROG} <options> "

  options[:app] = nil

  opts.on( '-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end

  opts.on( '-d', '--debug', 'Run in debug mode' ) do
    options[:debug] = true
  end

  opts.on( '-A', '--All', 'Get gc logs for All components' ) do
    options[:All] = true
  end

  opts.on( '-p', '--parallel <parallel degree>', 'Paralllel degree, default 10 ' ) do |parallel|
    options[:parallel] = parallel
  end


  opts.on( '-a', '--app <appname>', 'App name, e.g., leo' ) do |app|
    options[:app] = app
  end

  opts.on( '-m', '--machine <machine>', 'Machine name, e.g., ech3-leo21.prod' ) do |machine|
    options[:machine] = machine
  end

  opts.on( '-i', '--instance <instance>', 'Instance name, e.g., i002' ) do |instance|
    options[:instance] = instance
  end


end

optparse.parse!

#options.each_pair { |k,v| puts "#{k} : #{v}" }
#puts options
#puts options.class
#exit


$debug = options[:debug] ? options[:debug] : nil
$All = options[:All] ? options[:All] : nil
$parallel = options[:parallel] ? options[:parallel] : 10   # default to 10
$parallel = $parallel.to_i



def get_delta (params)

  # case 1: gc log did not change
  # case 2: the same gc log file changed with more lines 
  # case 3: a brand new gc log file is generated
  # any more cases?

  file_new = params[:new]
  file_prev = params[:prev]

  mod_time_prev = File.stat(file_prev).mtime
  mod_time_new = File.stat(file_new).mtime

  head_of_prev = `head #{file_prev}`
  head_of_new = `head #{file_new}`

  if  mod_time_new == mod_time_prev 
  
    # case 1: gc log did not change
    # no change
    puts "new file has not changed from prev file"
  
  else
  
    if head_of_new == head_of_prev
  
      # case 2: the same gc log file changed with more lines 
      # same file, but content changed, so get the delta
      puts "same file, but content changed, so get the delta"

      # 
      wcl_prev = `wc -l gc.log.prev | awk '{print $1}`
      
      delta_starting_line_number = wcl_prev.to_i + 1
      
      cmd = %( perl -ne 'print if #{delta_starting_line_number}..0' gc.log > poo )
      puts "generating delta: poo"
      
      system( cmd )
 
  
    else
    
      # case 3: a brand new gc log file is generated
      # new file, so get the whole file
      puts "new file, so get the whole new file"
    
    end
    
  end

end


def fetch_gc_logfile ( app, machine, instance )

  # backup the prev file first
#  cmd = %(cp -p gc.log gc.log.prev)
#  system( cmd )

  # fetch the gc logfile now
#  cmd = %(scp -p ech3-leo21.prod:/export/content/leo-tomcat/i001/logs/gc.log .)
#  cmd = %(scp -p ech3-leo28.prod:/export/content/leo-tomcat/i001/logs/gc.log .)
#  system( cmd )

  app_installed_dir = MYCM.get_installed_dir( 'ech3', app )


  drop_dir_str = "#{app}/#{machine}/#{instance}/#{$today}"
  drop_dir= "logs/prod/#{drop_dir_str}"

  # create local drop dir
  cmd_mkdir = %( mkdir -p #{drop_dir} )
  puts cmd_mkdir  if $debug
  system( cmd_mkdir )


  # create drop dir on siteops.md
  cmd_mkdir_remote = %( ssh siteops@siteops-md.foobar.biz "mkdir -p #{drop_dir}" )
  puts cmd_mkdir_remote  if $debug
  system( cmd_mkdir_remote )


 
  # scp to local
  cmd = %(scp -p #{machine}:/export/content/#{app_installed_dir}/#{instance}/logs/gc.log  #{drop_dir} )
  puts cmd if $debug
  system( cmd )


  # scp to siteops-md
 
  cmd = %(scp -p #{drop_dir}/gc.log  siteops@siteops-md.foobar.biz:#{drop_dir} )
#  cmd = %(scp -p #{machine}:/export/content/#{app_installed_dir}/#{instance}/logs/gc.log  siteops@siteops-md.foobar.biz:#{drop_dir_remote} )
  puts cmd if $debug
  system( cmd )



end




def main_single ( app, machine, instance )

  puts "#" * 80
  
  if app and machine

    fetch_gc_logfile( app, machine, instance  )

  else

    all_apps = MYCM.get_all_apps_of('ech3', 'array')
    all_apps.each do  |a|
      hosts = MYCM.get_hosts_of_app('ech3', 'str', a ) 
      puts a + " : " + hosts 
    end

  end
  
#  get_delta( :new=>'gc.log', :prev=>'gc.log.prev' )

end

def handle_people_search

  puts "Handling people-search here..."

end


def do_chunk ( chunk )

  chunk.each { |c|
    c.chomp
    #  c is an app
    #  no need to deal with agent and memcache*

    return if c =~ /agent/ || c =~ /memcache/

    # and handle people-search specifically
    if ( c =~ /people-search/ )

      handle_people_search
      return 

    end

    hosts = MYCM.get_hosts_of_app('ech3', 'str', c)
#    puts c + " : " + hosts

    hosts.split(/\s+/).each { |h|
      h.chomp
      puts "fetching gc.log for #{c} on #{h}..." if $debug
      fetch_gc_logfile( c, h, 'i001')
    }

  }

end


def main_all

  # all apps
  all_apps = MYCM.get_all_apps_of('ech3', 'array')

  all_apps.each_slice($parallel) do |chunk|

   do_chunk(chunk)

  end


end


if $0 == __FILE__

  app = options[:app] ? options[:app] : nil
  machine = options[:machine] ?  options[:machine] : nil  
  instance = options[:instance] ? options[:instance] : 'i001'

  if $All

    main_all

  else

    if app and machine and instance
      fetch_gc_logfile( app,  machine, instance )
    else
      STDERR.puts "I need --app, --machine, --instance" 
    end

  end

end
