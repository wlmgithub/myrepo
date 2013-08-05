#!/usr/bin/env ruby
#
# lwang:  The purpose of this script is to install GLU agent
#
require 'optparse'
STDOUT.sync = true

$ssh = "/bin/ssh"
$sudo = "/usr/local/bin/sudo"
$svcs = "/bin/svcs"
$svcadm = "/usr/sbin/svcadm"
$svccfg = "/usr/sbin/svccfg"
$pkgadd = "/usr/sbin/pkgadd"
$pkginfo = "/bin/pkginfo"

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

this_prog = __FILE__

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: #{this_prog} [options] host1 host2 ... "
  opts.banner += "\n\n\tinstall GLU agent on hosts... \n\n"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:enable] = false
  opts.on( '-e', '--enable', 'Enable an already installed glu agent' ) do
    options[:enable] = true
  end

  options[:disable] = false
  opts.on( '-d', '--disable', 'Disable an already installed glu agent' ) do
    options[:disable] = true
  end

  options[:file] = nil
  opts.on( '-f', '--file FILE', 'Read from FILE to get a list of hosts' ) do|file|
    options[:file] = file
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
optparse.parse!

hosts = []

if ARGV.empty?
  if  options[:file] == nil

    puts "I need one or more hosts."
    puts "For usage: \"#{this_prog} -h\" "
    exit

  else

    file = options[:file]
    puts "INFO: using file: " + file if options[:verbose]
    unless File.exist?(file)
      puts "ERROR: file " + file +  " does not exists"
      exit 
    end
    hosts = File.readlines(file)

  end
else
  if options[:file]
    puts "-f and hosts ... are mutually exclusive."
    exit
  else
    hosts = ARGV
  end
end


puts "INFO: working on hosts : " + hosts.join(" ") if options[:verbose]

# now that we have the hosts... let's roll


# needs ITOPS_HOME
itops_home = ENV['ITOPS_HOME']

unless itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end

link_glu_agent_pkg_file = "LINKgluagent.pkg"
agent_pkg_file = "#{itops_home}/glu/agent/#{link_glu_agent_pkg_file}"

#puts agent_pkg_file  if options[:verbose]

# grab pwd 
print "Enter password (kerberos): "
system("stty -echo")
pwd = STDIN.gets.chomp
system("stty echo")

# foreach host...
hosts.each do |h|
  h.chomp! if h.include?("\n")
  puts
  system("echo #{pwd} | #{$ssh} #{h} #{$sudo}  ls >/dev/null 2>&1")
#  system(%(#{$ssh} #{h} "#{$sudo} -l " ) )

  # check whether glu agent pkg is already installed
  res = %x(#{$ssh} #{h} " #{$pkginfo} | grep gluagent " )
  unless res.empty?
    puts "INFO: Looks like glu agent is already installed on #{h}. " if options[:verbose]
#    system( %(#{$ssh} #{h} "rm #{link_glu_agent_pkg_file} " ) )

    if options[:enable]
      # if --enable is given, enable it

      res = %x( #{$ssh} #{h} " #{$svcs} -a | grep gluagent | cut -d' ' -f1  "  )
      if res.chomp == "online" 
        puts "INFO: Looks like glu agent is already enabled on #{h}. No bother."
        next
      end
    
      # ... and enable it
      cmd_enable = %( #{$ssh} #{h} " #{$sudo} #{$svcadm} enable  /application/gluagent:default ")
      puts "INFO: enabling  #{link_glu_agent_pkg_file}  on host #{h}" if options[:verbose]
      system( cmd_enable )
    
      # check it's enabled
      cmd_check_enabled = %( #{$ssh} #{h} " #{$svcs} -a | grep gluagent "  )
      system( cmd_check_enabled )

    end

    if options[:disable]
      # if --disable is given, disable it

      res = %x( #{$ssh} #{h} " #{$svcs} -a | grep gluagent | cut -d' ' -f1  "  )
      if res.chomp == "online" 
        puts "INFO: disabling  #{link_glu_agent_pkg_file}  on host #{h}" if options[:verbose]
        # disable it
        cmd_enable = %( #{$ssh} #{h} " #{$sudo} #{$svcadm} disable  /application/gluagent:default ")
        system( cmd_enable )
      end
    
    end

    next
  end

  # if not installed, xfer the pkg
  puts "Transfering pkg to host #{h}..."
  cmd_scp = %(scp #{agent_pkg_file} #{h}:~)
  system( cmd_scp  )

  # if not installed, install it
  cmd_install = %( #{$ssh} #{h} " echo 'all' |  #{$sudo} #{$pkgadd} -d #{link_glu_agent_pkg_file} " )
  puts "INFO: installing #{link_glu_agent_pkg_file} on host #{h}" if options[:verbose]
  system( cmd_install )

  # once installed, import glu-agent.xml ...
  cmd_import = %(  #{$ssh} #{h} " #{$sudo} #{$svccfg} import /var/svc/manifest/LINK/glu-agent.xml  ")
  puts "INFO: importing glu-agent.xml  on host #{h}" if options[:verbose]
  system( cmd_import ) 

  # ... and enable it
  cmd_enable = %( #{$ssh} #{h} " #{$sudo} #{$svcadm} enable  /application/gluagent:default ")
  puts "INFO: enabling  #{link_glu_agent_pkg_file}  on host #{h}" if options[:verbose]
  system( cmd_enable )

  # check it's enabled
  cmd_check_enabled = %( #{$ssh} #{h} " #{$svcs} -a | grep gluagent "  )
  system( cmd_check_enabled )
  
#  system(" echo#{$ssh} #{h} #{$sudo} -l")

  # no litter
  system( %(#{$ssh} #{h} "rm #{link_glu_agent_pkg_file} " ) )
end

exit

