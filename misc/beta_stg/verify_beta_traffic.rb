#!/usr/bin/env ruby
#
# lwang:  The purpose of this script is to verify no beta traffic going to alpha boxes
#	
#	algorithm suggested by Tony: make sure no beta hostnames appear in the public access logs on alpha hosts
#
# needs ITOPS_HOME
itops_home = ENV['ITOPS_HOME']

unless itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end

hosts_beta_all_file = "#{itops_home}/conf/hosts_beta_all"

#puts hosts_beta_all_file

# get all alpha hosts
all_alpha_hosts = []

#all_alpha_hosts = File.open( "#{itops_home}/conf/hosts_stg_all"  ).readlines
File.open("#{itops_home}/manif/manifest_stg").each_line  do |line|
#  puts line
  line.chomp
  if line =~ /.*\t(.*)/
    $1.split(/\s+/).each { |s| 
      all_alpha_hosts.push(s)
    }
  end
end

=begin
puts "======"
all_alpha_hosts.sort.uniq.each do |h|
  puts "===#{h}==="
end
=end

all_alpha_hosts.sort.uniq.each do |ha|
  ha.chomp!
  #puts ha

  # xfer hosts beta_all file
  cmd = %( scp #{hosts_beta_all_file} #{ha}:~ )
  #puts cmd
  system( cmd )

  # xfer grep_alpha.sh file
  cmd = %( scp "grep_alpha.sh" #{ha}:~   )
  #puts cmd
  system( cmd )

  # analyze
  puts "Looking for beta traffic on #{ha}..."
  res = %x( ssh  #{ha}  "./grep_alpha.sh"  )
  unless res.empty?
    
    puts "Found!: " + res

  end

  # no litter
  cmd = %( ssh #{ha} "rm  grep_alpha.sh hosts_beta_all" )
  system( cmd )
  
end



exit

# xfer hosts beta_all file
cmd = %( scp #{hosts_beta_all_file} esv4-auth01.stg:~ )
puts cmd
