#!/usr/bin/env ruby
#
# lwang:  Do it massively by taking in a file with a list of components
#
require 'optparse'

options = {}

this_prog = __FILE__

# needs ITOPS_HOME
itops_home = ENV['ITOPS_HOME']

unless itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end


optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{this_prog} [options] "

  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:file] = nil
  opts.on( '-f', '--file FILE', 'Read components from  FILE' ) do|file|
    options[:file] = file
  end

  options[:env] = nil
  opts.on( '-e', '--env ENV', 'Environment: e.g., stg, beta, ech3' ) do|env|
    options[:env] = env
  end

  options[:operation] = nil
  opts.on( '-o', '--operation OPERATION', 'Action to take: pause or resume' ) do|operation|
    options[:operation] = operation
  end


  options[:execute] = false
  opts.on(  '--execute', 'Really do it! USE IT ONLY IF YOU KNOW WHAT YOU ARE DOING!' ) do
    options[:execute] = true
  end

  options[:noask] = false
  opts.on( '-n', '--noask', 'Do not ask' ) do
    options[:noask] = true
  end


  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end

end

optparse.parse!

unless  options[:file]
  puts "Usage: #{this_prog} -h"
  exit
end

file = options[:file]

unless options[:env]
  puts "I need -e ENV"
  exit
end

env = options[:env]

unless options[:operation]
  puts "I need -o OPEARATON"
  exit
end

opt_operation = options[:operation]

if options[:verbose]
  puts "Being verbose"
  puts "Environment:  #{env}" 
  puts "Operation:  #{opt_operation}" 
  puts "File to read from: #{file}"
end

comps = File.readlines(file)
puts "Components :\n#{comps}"   if options[:verbose]

def get_all_comps_in_mapping

  comps = `cat mapping | grep -v '^#' | cut -f1 | xargs`
  
end

def get_all_comps_in_manifest (itops_home, env)

  comps = `cat #{itops_home}/manif/manifest_#{env} | cut -f1 | xargs`

end


def get_comp_real_action (c, opt_operation)

  # els     __OPERATION__UpdatesFromDatabus
  # data-platform-filtering __OPERATION__

  File.open("mapping", "r").each_line  { |line|
    line.chomp!
    next if line.empty? or line =~ /^#/
    #puts "#{line}"
    if line =~ /(.*?)\s+(.*?)\t.*/
      app = $1
      op = $2
      #puts "#{app} #{c} #{op}"

      if app == c
        if opt_operation == 'pause' 
          if  op == '__OPERATION__'
            return 'pause'
          elsif op == '__OPERATION__UpdatesFromDatabus'
            return 'suspend'
          end
        elsif opt_operation == 'resume'
          if  op == '__OPERATION__'
            return 'resume'
          elsif op == '__OPERATION__UpdatesFromDatabus'
            return 'restart'
          end
        else
          puts "ERROR: I only take operations: pause, resume"
          exit
        end
  
      end

    end
  }

end

all_comps_in_mapping = get_all_comps_in_mapping
all_comps_in_manifest = get_all_comps_in_manifest(itops_home, env)

#p all_comps_in_manifest

#p all_comps_in_mapping.split

comps.each do  |c|
  c.chomp!
  unless  all_comps_in_mapping.split.include? c
    puts "ERROR: #{c} is not in the mapping file! "
    exit
  end
end

comps.each do |c|
  c.chomp!
  unless all_comps_in_manifest.split.include? c
    puts "ERROR: #{c} is not in manifest file"
    exit
  end
end


# now that c is in both mapping and manifest... 

# ./doit.pl  -comp els -o suspend --env ech3


other_args = ''

other_args += ' --execute ' if options[:execute]
other_args += ' --noask ' if options[:noask]

puts "other_args: " +  other_args if options[:verbose]

comps.each do |c|
  c.chomp!
  action = get_comp_real_action(c,opt_operation)

  #puts c + " " + action + " " + env
  cmd = %( ./doit.pl --comp #{c} --operation #{action} --environment #{env} #{other_args} )
  
  unless options[:execute]

    puts "INFO: would have run: " +  cmd  

  else 

    system( cmd )

  end
end
