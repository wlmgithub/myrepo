#!/bin/env ruby
#
# wcatron: This script will look through each subdirectory (app) under the specified CCS structure, and check to make
# sure each one has a server_conf with CONTAINER_SERVER_PORT defined.  For any apps which don't have it, the appropriate
# port will be parsed from the specified prod.config and appended to the corresponding server_conf in your tree.
#
# Any portless apps which aren't resolved will be listed upon completion of the script
#
# assumptions:
#   - you're running this on a mac
#   - each app in your CCS tree already has a server_conf.sh file [at the top (app) level!]
#   - you don't use this for peopleSearch
#

require 'find'
require 'ftools'
require 'optparse'

THIS_PROG = __FILE__
PORT_PROPERTY = "CONTAINER_SERVER_PORT"
CONF_FILE_NAME = "server_conf.sh"

def usage ( me )
  puts "usage:  #{me} -d <topdir> -c <prod_config_file>"
  exit
end

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "usage: #{THIS_PROG} <options>  "

  options[:dir] = nil
  opts.on( '-d', '--dir <topdir>', 'Topdir to work on, e.g., /export/content/jetty_container/stg_server_conf' ) do |dir|
    options[:dir] = dir
  end

  opts.on( '-c', '--config <file>', 'prod.config file to find missing ports from' ) do |file|
    options[:config_file] = file
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

DO_IT = options[:execute]
TOP_DIR = (options[:dir] =~ /\/$/) ? options[:dir].chop : options[:dir]
PROD_CONFIG_FILE = options[:config_file]

usage(THIS_PROG) unless TOP_DIR and PROD_CONFIG_FILE
usage(THIS_PROG) unless File.directory?(TOP_DIR) and File.exists?(PROD_CONFIG_FILE)

# parse the prod config file to build a manifest of app/ports
@prod_config_manifest = {}
names_apps = {}

file = File.open(PROD_CONFIG_FILE)
file.each_line do |line|
  if matchdata = /^(.*)\.container=(.*)$/.match(line)
    name, app = matchdata[1], matchdata[2]
    names_apps[name] = app
  elsif matchdata = /^(.*)\.port=(\d+)$/.match(line)
    name, port = matchdata[1], matchdata[2]
    @prod_config_manifest[names_apps[name]] = port
  end
end
puts @prod_config_manifest.inspect
file.close

# simple structure to represent an app, all of it's server_conf files, and whether it's "complete" (has all PORTs defined)
class App < Struct.new(:name, :server_confs, :complete); end

# build a list of all the apps in your tree, along with corresponding server_confs and ports
# also tag each one as complete or not
apps_with_conf = []
Find.find(TOP_DIR) do |file|
  next unless File.directory? file and File.dirname(file) == TOP_DIR
  app = file.split("/").last
  this_app = App.new(app)
  this_app.server_confs = {}
  Find.find(File.join(TOP_DIR, app)) do |path|
    this_app.server_confs[path] = nil if path =~ /server_conf.sh$/
  end
  this_app.server_confs.each do |file, port|
    contents = File.read(file)
    matchdata = /#{PORT_PROPERTY}=(\d+)/.match(contents)
    matchdata ? port = matchdata[1] : port = nil
    this_app.server_confs[file] = port
  end
  this_app.complete = true
  this_app.server_confs.each { |file, port| this_app.complete = false unless port }
  apps_with_conf << this_app
end

# split the apps into two groups
complete_apps, incomplete_apps = [], []
apps_with_conf.each { |a| a.complete ? complete_apps << a : incomplete_apps << a }

puts "*" * 76
puts "Complete apps: #{complete_apps.length}"
puts "Incomplete apps: #{incomplete_apps.length}"
puts "*" * 76

resolved = []
still_unresolved = []

# add the appropriate port from prod.config to each server_conf for every incomplete app
incomplete_apps.each do |app|
  puts "\nAttempting to resolve ports for #{app.name}..."
  port = @prod_config_manifest[app.name]
  if port
    puts "\tFound port! -- #{port}"
    new_port_line = "#{PORT_PROPERTY}=#{port}"
    app.server_confs.each do |file, existing_port|
      puts "\tAppending to #{file}:" + new_port_line
      command = "echo #{new_port_line} >> #{file}"
      command = "echo #{new_port_line} > /tmp/tmp_conf.sh; cat #{file} >> /tmp/tmp_conf.sh ; mv /tmp/tmp_conf.sh #{file}"
      `#{command}` if DO_IT
    end
    resolved << app
  else
    still_unresolved << app
    puts "\tWARNING: PORT NOT FOUND AND STUFF"
  end
end

puts "*" * 76
puts "Resolved apps: #{resolved.length}"
puts "Still Unresolved apps: #{still_unresolved.length}"
puts "\nThe following may need manual attention:"
still_unresolved.each { |app| puts "\t#{app.name}" }
