#!/bin/env ruby
#
# lwang: This ad-hoc script is to walk through a directory structure that contains
#	server_conf.sh. Inspect for each app to see if it contains one or more than one 
#	server_conf.sh file, and act accordingly:
#
#		* if there is only one server_conf.sh, move it to the app level
#		* if there are more than one server_conf.sh, 
#			* if no diff between them, then move any one to the app level
#			* if there is any diff between them, report and do manually
#
#	NOTES:  for real execution, change "<move cmd>" to real move command.... could have done it better, but it's ad-hoc anyway...
#

require 'find'
require 'ftools'
require 'optparse'

thisprog = __FILE__

def usage ( me )
  puts "usage:  #{me} -h"
  exit
end

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "usage: #{thisprog} <options>  "

  options[:dir] = nil
  opts.on( '-d', '--dir <topdir>', 'Topdir to work on, e.g., /export/content/jetty_container/stg_server_conf' ) do |dir|
    options[:dir] = dir
  end

  opts.on( '-e', '--execute', 'Really execute it!' ) do
    options[:execute] = true
  end

  opts.on( '-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end
end

optparse.parse!


#topdir = "/export/content/jetty_container/stg_server_conf"

$doit = options[:execute]

topdir = options[:dir]

usage( thisprog )  unless topdir

topdir = topdir.chop if topdir =~ /\/$/

puts "Top level directory: " + topdir

hash = Hash.new(Array.new) # holds the appname => [ filenames ] hash, shoud be given a better name, oh well...

apps_with_one_file = Array.new
apps_with_more_than_one_file = Array.new
apps_with_more_than_one_file_no_diffs = Array.new
apps_with_more_than_one_file_with_diffs = Array.new

#puts topdir


Find.find( topdir ) do |path|
  
  if File.file?(path) and path =~ /#{topdir}\/(.*)/
    relative_file = $1
    appname = $1.split("/")[0]

    #puts path + " : " + relative_file + " : " + appname + " : "

    hash[appname] += [relative_file]

  end

end


puts "~~~~~~~~~~~~~~~~~~~~~~~~~"


def do_move(topdir, appname, relative_file)
#  puts "------> in do_move"
  puts "\nRunning: mv  #{topdir}/#{relative_file}   #{topdir}/#{appname}"
  puts
  if $doit
    system("mv  #{topdir}/#{relative_file}   #{topdir}/#{appname}")
  end
end


hash.each { |k,v| 
  puts "\n========== Handling #{k} ========= "
  print k + " => " 
  print v.join("\n\t")
  puts "\n"
  if v.size == 1
    apps_with_one_file.push(k)
    do_move(topdir, k, v[0])
  end

  if v.size > 1
    apps_with_more_than_one_file.push(k)

    first_file = v.shift

    diff_count_of = Hash.new
    diff_count_of[k] = 0

    v.each do |f|
#      puts ">>>>" + "#{topdir}/"+first_file + "\t" + "#{topdir}/"+f
      puts "Running: diff " + "#{topdir}/"+first_file + "\t" + "#{topdir}/"+f + "\n"
#      %x(diff "#{topdir}/#{first_file}" "#{topdir}/#{f}" )
      system("diff #{topdir}/#{first_file} #{topdir}/#{f}" )
      if $?.exitstatus  != 0
        diff_count_of[k]  = diff_count_of[k] + 1
      end
    end

    v.unshift( first_file )

    v.each do |f|
      if diff_count_of[k] != 0
        apps_with_more_than_one_file_with_diffs.push(k)
        ##############################################
        # needs manual intervention here !!!
        ##############################################
      else
        apps_with_more_than_one_file_no_diffs.push(k)
        do_move(topdir, k, v[0])
        
        v.shift
        v.each do |r|
          puts "Running: rm #{topdir}/#{r}\n"
          if $doit
            system("rm #{topdir}/#{r}")
          end
        end

        break
      end
    end

  
  end
}

if $doit
  
  #
  # remove empty dirs, clean once
  #
  Dir["#{topdir}/**/*"].select{ |d| File.directory? d}.select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }.each { |d| Dir.rmdir d }

  #
  # if server_conf.sh file only exists in one instance, move it to machine level,
  #	otherwise, leave it alone
  #
  hash2 = Hash.new(Array.new)
  
  Find.find( topdir ) do |path|
    if File.file?(path) and path =~ /#{topdir}\/(.*?)\/(.*?)\/(.*?)\/server_conf.sh/
      app = $1
      machine = $2
      inst = $3
      #puts path + " : " + app + " : " + machine + " : "  + inst
      hash2[app+"/"+machine] += [inst]
    end
  end
  
  hash2.each { |k,v|
    #puts k + " => " + v.join(" ")
    # only deal with this case, otherwise, leave it alone for manual cleanup
    if v.size == 1
      inst = v[0]
      #puts "#{topdir}/#{k}/#{inst}/server_conf.sh #{topdir}/#{k}"
      system( "mv #{topdir}/#{k}/#{inst}/server_conf.sh  #{topdir}/#{k}" )
    end
  
  }
  
  #
  # remove empty dirs, clean twice
  #
  Dir["#{topdir}/**/*"].select{ |d| File.directory? d}.select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }.each { |d| Dir.rmdir d }
 
end

#
#  reports
#
puts "\n========= apps_with_one_file " 
puts apps_with_one_file.sort.uniq
puts apps_with_one_file.sort.uniq.size

puts "\n========= apps_with_more_than_one_file "
puts apps_with_more_than_one_file.sort.uniq
puts apps_with_more_than_one_file.sort.uniq.size

puts "\n========= apps_with_more_than_one_file_no_diffs"
puts apps_with_more_than_one_file_no_diffs.sort.uniq
puts apps_with_more_than_one_file_no_diffs.sort.uniq.size

puts "\n========= apps_with_more_than_one_file_with_diffs"
puts <<EOM
        ##############################################
        # needs manual intervention here !!!
        ##############################################
EOM
puts apps_with_more_than_one_file_with_diffs.sort.uniq
puts apps_with_more_than_one_file_with_diffs.sort.uniq.size

