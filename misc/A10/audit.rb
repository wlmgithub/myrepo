#!/bin/env ruby
#
# lwang:  find all prod/ech3 hosts that has 'clb01' or 'clb02' in the netstat output
#
require 'optparse'
require 'socket'
require 'rexml/document'
include REXML

host = Socket.gethostname

if host != 'rotozip.corp'
  warn 'You have to run me on rotozip.'
  exit
end


def display_instruction_for_relrepo
  msg = <<-MSG

	It appears that you do not have RELREPO env var set. RELREPO is supposed to be an env var pointing to a checked out directory of relrepo.
	
	Here is what you can do:

		* if you already have a checkout of relrepo, just set RELREPO env to point to it: 
			export RELREPO=<path_to_your_relrepo_dir>
		* if you do not have a checkout of relrepo, check it out using the following URL:
			svn+ssh://svn.corp.foobar.com/relrepo/network/trunk 
		  then set the RELREPO env var.

  MSG

  puts msg

end

# split an array into equal sizes
class Array
  def / len
    a = []
    each_with_index do |x,i|
      a << [] if i % len == 0
      a.last << x
    end
    a
  end
end



relrepo_root = ENV['RELREPO']
itops_home = ENV['ITOPS_HOME'] 

if relrepo_root == nil
  display_instruction_for_relrepo()
  exit
end


gen_manif_from_glu_scr = "#{itops_home}/glu/bin/gen_manif_from_glu.rb"

#puts gen_manif_from_glu_scr

puts "Getting prod host list..."
all_hosts = ` #{gen_manif_from_glu_scr} --env ech3 --gethosts 2>/dev/null  | grep -v 'At revision'  `

#puts all_hosts
all_pxy_hosts = all_hosts.split("\n").grep /pxy/

puts "all pxy hosts: "
puts all_pxy_hosts

def audit_host( host ) 

  ssh = '/bin/ssh'
  netstat = '/bin/netstat'
  grep = '/bin/egrep' 

  cmd = %( #{ssh} #{host} ' #{netstat} | #{grep} "clb01|clb02" ' 2>/dev/null )  

  res = ` #{cmd} `


  #puts "============ #{host}"
  #puts "running cmd: #{cmd}"

  unless res == ''
    puts "============ #{host}"
    puts res 
  end
  

end

thr = Array.new
chunks = all_hosts.split("\n") / 10


puts "Checking each host now..."
puts "The following hosts ( excluding pxy hosts )  contain clb01 or clb02 in their netstat output:"
puts
chunks.each do |c|

  i = 0
  c.each do |h|
    thr[i] = Thread.new {

      h.chomp!
      audit_host( h ) unless h =~ /pxy/

    }
    i += 1
  end

  thr.each { |t|
    t.join
  }

end




exit
__END__

