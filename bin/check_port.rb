#!/usr/bin/ruby
#
# lwang: check port for each app
# 

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

itops_home = ENV['ITOPS_HOME']

progname = __FILE__

def usage ( me )
  puts <<-"USG"

	#{me}  <env>

	USG
end


if ARGV.size == 0
  usage( progname )
  exit
end

env = ARGV[0]

puts env

#env=${1:?"I need an env, e.g., stg / ech3"}

#for i in `./cmtool.pl -a get_pools -env  $env`; do  ./gen_app_port_mapping.pl -e $env -a $i; done

#system("#{itops_home}/bin/cmtool.pl -a get_pools -env #{env}")

all_pools = %x( #{itops_home}/bin/cmtool.pl -a get_pools -env #{env} )

port_of = Hash.new
thr = Array.new


#puts all_pools
all_pools_array = all_pools.split(/ /)

chunks = all_pools_array / 10


#puts all_pools_array.size


chunks.each do  |c|
  i = 0
  c.each do |pool|
    thr[i] = Thread.new {
      retval = ` #{itops_home}/bin/gen_app_port_mapping.pl -e #{env} -a #{pool} `

      retval.split(/\n/).each { |line|  
        if line =~ /(.*)\t(.*)/
          port_of[$1] = $2
        end
      }
    }
    i += 1
  end
  
  thr.each { |t|
    t.join
  }
  
end

port_of.sort.each { |k,v|
  print k, "\t", v, "\n"
}

exit

# normal way
all_pools_array.each do |pool|
  retval = ` #{itops_home}/bin/gen_app_port_mapping.pl -e #{env} -a #{pool} `
  if retval =~ /(.*)\t(.*)/
#    print $1, " ==> " , $2, "\n"
    port_of[$1] = $2
  end
end


