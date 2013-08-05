#!/bin/env ruby
#
# lwang: one-off script 
#

service =  ARGV[0]

itops_home = ENV['ITOPS_HOME']
$gen_manif_from_glu_scr = itops_home + '/glu/bin/gen_manif_from_glu.rb'


def get_first_machine_of( service )
  
  cmd = %( #{$gen_manif_from_glu_scr} -n -e ech3 -s #{service} )
  hosts = %x( #{cmd} )

  puts hosts

  first =  hosts.split().first

end


def get_cache_size( machine, cache_dir )

  system( " ssh #{machine} ' ls -lh  #{cache_dir}' " )

#  cmd = %( ssh #{machine} " du -ksh #{cache_dir}  | awk '{print $1}' " )
  cmd = %( ssh #{machine} ' du -ksh #{cache_dir}  | tail -1 | awk "{print $1}" ' )
  res = %x( #{cmd} )

end


first_machine = get_first_machine_of( service )

puts first_machine

cache_dir = '/export/content/' + service + '/i001_caches/' 

puts cache_dir

res = get_cache_size( first_machine, cache_dir )

puts res
