#!/bin/env ruby
#
# lwang: generate manifest from GLU
#
require 'optparse'
require 'socket'
require 'rexml/document'
include REXML

#host = Socket.gethostname
#
#if host != 'rotozip.corp'
#  warn 'You have to run me on rotozip.'
#  exit
#end

options = {}

optparse = OptionParser.new do |opts|

  opts.banner = "usage: " + __FILE__ + " [options ] "

  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more info') do
    options[:verbose] = true
  end

  options[:nosvn] = false
  opts.on( '-n', '--nosvn', 'No svn update for relrepo') do
    options[:nosvn] = true
  end


  options[:gethosts] = false
  opts.on( '-g', '--gethosts', 'Get all hosts') do
    options[:gethosts] = true
  end

  options[:getsvcs] = false
  opts.on( '-g', '--getsvcs', 'Get all services') do
    options[:getsvcs] = true
  end

  options[:getcps] = false
  opts.on( '-g', '--getcps', 'Get all context paths ') do
    options[:getcps] = true
  end

  options[:getwars] = false
  opts.on( '-g', '--getwars', 'Get all wars') do
    options[:getwars] = true
  end

  options[:getcp] = nil
  opts.on( '-g', '--getcp SVC', 'Get context path of a given SVC') do |getcp|
    options[:getcp] = getcp
  end

  options[:getconfigref] = nil
  opts.on( '-g', '--getconfigref SVC', 'Get configRef of a given SVC') do |getconfigref|
    options[:getconfigref] = getconfigref
  end


  options[:getwar] = nil
  opts.on( '-g', '--getwar SVC', 'Get war of a given SVC') do |getwar|
    options[:getwar] = getwar
  end

  options[:getclusters] = nil
  opts.on( '-g', '--getclusters SVC', 'Get clusters of a given SVC') do |getclusters|
    options[:getclusters] = getclusters
  end


  options[:env] = nil
  opts.on( '-e', '--env ENV', 'Get env (currently supported: stg, beta, ech3, ei1, ei3, ela4' ) do |env|
    options[:env] = env
  end

  options[:svc] = nil
  opts.on( '-s', '--svc SVC', 'Get hosts running SVC '  ) do |svc|
    options[:svc] = svc
  end

  options[:host] = nil
  opts.on( '-h', '--host HOST', 'Get services running on HOST'  ) do |host|
    options[:host] = host
  end


  opts.on( '-h', '--help', 'Display help screen') do
    puts opts
    exit
  end

end
optparse.parse!

# env required
if options[:env] == nil
  puts optparse.help()
  exit
end

env_a = options[:env]

unless env_a.include?('stg') \
	or env_a.include?('beta')  \
	or env_a.include?('ech3') \
	or env_a.include?('ei1') \
	or env_a.include?('ei3') \
	or env_a.include?('ela4')

  puts "env allowed: ei1, ei3, ela4, stg, beta, or ech3"
  exit
end

env = env_a.to_s

env_dir = case env
  when 'stg'
    'STG-ALPHA'
  when 'beta'
    'STG-BETA'
  when 'ech3'
    'PROD-ECH3'
  when 'ela4'
    'PROD-ELA4'
  when 'ei1'
    'EI1'
  when 'ei3'
    'EI3'
end

machine_suffix = case env
  when 'stg' 
   'stg' 
  when 'beta'
    'stg'
  when 'ech3'
    'prod'
end

#puts env_dir




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


def update_topo_root_dir( dir ) 
  Dir.chdir( dir )
  svn_cmd_update = %( svn update )
  system( svn_cmd_update )
end


def get_all_xml_files(  topo_root_dir, env_dir  )

  xml_dir = topo_root_dir + "/" + env_dir

  d  = Dir.chdir( xml_dir )
  all_xml_files = Dir.glob("*.xml")

end


def gen_manifest( topo_root_dir, env_dir  ) 

  all_xml_files = get_all_xml_files(  topo_root_dir, env_dir  )
  all_xml_files.to_a.sort.each do  |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)
    
    doc.elements.each('topology/container') do |p|
      
      app =  p.attributes['name']
  
      machines_of_app = Hash.new(Array.new)
  
      p.elements.each('//entry') { |e|
        machines_of_app[app] << e.attributes['host']
      }
  
      print app + "\t"
      print machines_of_app[app].join(' ')
      puts
  
    end
    
  end

end


def gethosts( topo_root_dir, env_dir  ) 

  all_hosts = []
  all_xml_files = get_all_xml_files(  topo_root_dir, env_dir  )
  all_xml_files.to_a.sort.each do  |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)
    
    doc.elements.each('//entry') do |p|
      all_hosts << p.attributes['host']  
    end
    
  end

  puts all_hosts.sort.uniq

end

def getsvcs( topo_root_dir, env_dir  ) 

  all_svcs = []
  all_xml_files = get_all_xml_files(  topo_root_dir, env_dir  )
  all_xml_files.to_a.sort.each do  |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)
    
    doc.elements.each('topology/container') do |p|
      all_svcs << p.attributes['name']  
    end
    
  end

  puts all_svcs.sort.uniq

end

def parse_container_file ( file )

  wars_of_app = Hash.new()

  # container_file is an XML file
  xml = File.read( file )
  doc = REXML::Document.new( xml )

  doc.elements.each('containers/container') do |c|        
    app = c.attributes['name']
#    print app + " : "  
    c.elements.each('./war') { |e|
#      puts  " " + e.attributes['ref'] 
      wars_of_app[app] ||= []
      wars_of_app[app] <<  e.attributes['ref']
    } 
#    puts "<br>"

  end

  wars_of_app

end

def getwars( container_file )

  wars_of_app = Hash.new()

  xml = File.read( container_file )
  doc = REXML::Document.new( xml )

  doc.elements.each('containers/container') do |c|
    app = c.attributes['name']
    c.elements.each('./war') { |e|
      wars_of_app[app] ||= []
      wars_of_app[app] << e.attributes['ref']
    }
  end

  puts wars_of_app.values.sort.uniq

end


def getwar( container_file, app_given ) 

  war_of = Hash.new(Array.new)

  xml  = File.read( container_file )
  doc = REXML::Document.new( xml )

  doc.elements.each('containers/container') do |c|
    app = c.attributes['name']
    if app == app_given
      c.elements.each('./war') { |e|
        war_of[app] ||= []
        war_of[app] << e.attributes['ref']
      }
    end
  end
  puts war_of[app_given].sort.uniq

end


def getcps( container_file  ) 

  all_cps = []

  xml  = File.read( container_file )
  doc = REXML::Document.new( xml )

  doc.elements.each('//war') {  |e| 

    cp = e.attributes['contextPath']
    all_cps << e.attributes['contextPath']  unless  cp  == nil

  }

  puts all_cps.sort.uniq
 
end


def getcp( container_file, app_given ) 

  # hmm... a container may have more context paths, yuck
  cp_of = Hash.new(Array.new)

  xml  = File.read( container_file )
  doc = REXML::Document.new( xml )

  doc.elements.each('containers/container') do |c|
    app = c.attributes['name']
    if app == app_given
      c.elements.each('./war') { |e|
        cp = e.attributes['contextPath']
        cp_of[app] ||= []
        cp_of[app] << e.attributes['contextPath']
      }
    end
  end
  puts cp_of[app_given].sort.uniq

end

def getconfigref( container_file, app_given ) 

  configref = nil

  xml  = File.read( container_file )
  doc = REXML::Document.new( xml )

  doc.elements.each('containers/container') do |c|
    app = c.attributes['name']
    if app == app_given
      configref = c.attributes['configRef']
    end
  end
#  puts configref
  unless configref == nil
    print 1
  else
    print 0
  end

end


def get_clusters_for_svc( topo_root_dir, env_dir, svc_given )

  clusters_of_app = Hash.new(Array.new)

  all_xml_files = get_all_xml_files(  topo_root_dir, env_dir  )
  all_xml_files.to_a.sort.each do  |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)
    
    doc.elements.each('topology/container') do |p|
      app = p.attributes['name']
      if app == svc_given
        p.elements.each('//cluster') { |e|
          clusters_of_app[app] << e.attributes['name']
          c =  e.attributes['name']
          puts c
          e.elements.each('./entry') { |entry|
            host = entry.attributes['host']
            inst = entry.attributes['instance']
            print "\t", host, ' ', inst ,"\n"
          }
        }
      end
    end
  end
#  puts clusters_of_app[svc_given].sort.uniq

end



def get_hosts_for_svc( topo_root_dir, env_dir, svc_given )

  machines_of_app = Hash.new(Array.new)

  all_xml_files = get_all_xml_files(  topo_root_dir, env_dir  )
  all_xml_files.to_a.sort.each do  |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)
    
    doc.elements.each('topology/container') do |p|
      app = p.attributes['name']
      if app == svc_given
        machines_of_app = Hash.new(Array.new)
        p.elements.each('//entry') { |e|
          machines_of_app[app] << e.attributes['host']
        }
      end
    end
  end
  puts machines_of_app[svc_given].sort.uniq

end


def get_services_for_host( topo_root_dir, env_dir, host_given )

  apps_of_machine = Hash.new(Array.new)

  all_xml_files = get_all_xml_files(  topo_root_dir, env_dir  )
  all_xml_files.to_a.sort.each do  |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)
    
    doc.elements.each('topology/container') do |p|
      app = p.attributes['name']
      p.elements.each('//entry') { |e|
        h = e.attributes['host']
        if host_given == h
          apps_of_machine[host_given] << app
        end
      }
    end
  end
  puts apps_of_machine[host_given].sort.uniq

end



relrepo_root = ENV['RELREPO']

if relrepo_root == nil
  display_instruction_for_relrepo()
  exit
end

topo_root_dir = ENV['RELREPO'] + '/topologies'
#topo_root_dir = '/export/content/http/i001/htdocs/cm/glu/topologies'

model_root_dir = ENV['RELREPO'] + '/model/src' 
container_file = model_root_dir + '/containers_OPS.xml'


# if --nosvn, do not svn update for relrepo
unless options[:nosvn]
  # now that we have RELREPO, update it first
  update_topo_root_dir( topo_root_dir )
end


##### gethosts
if options[:gethosts] and options[:env]
  
  gethosts( topo_root_dir, env_dir  )
  exit

end

##### getsvcs
if options[:getsvcs] and options[:env]
  
  getsvcs( topo_root_dir, env_dir  )
  exit

end

##### getwars
if options[:getwars] and options[:env]

  getwars( container_file )
  exit

end

##### getwar
if options[:getwar] and options[:env]
  
  app_given =  options[:getwar] 
  getwar( container_file, app_given  )
  exit

end


##### getcps
if options[:getcps] and options[:env]
  
  getcps(  container_file  )
  exit

end


##### svc
if options[:svc] and options[:env]
  
  svc_given =  options[:svc] 
  get_hosts_for_svc( topo_root_dir, env_dir, svc_given  )
  exit

end

##### getclusters
if options[:getclusters] and options[:env]
  
  svc_given =  options[:getclusters] 
  get_clusters_for_svc( topo_root_dir, env_dir, svc_given  )
  exit

end



##### host
if options[:host] and options[:env]
  
  host_given =  options[:host] 
  get_services_for_host( topo_root_dir, env_dir, host_given  )
  exit

end

##### getcp
if options[:getcp] and options[:env]
  
  app_given =  options[:getcp] 
  getcp( container_file, app_given  )
  exit

end

##### getconfigref
if options[:getconfigref] and options[:env]
  
  app_given =  options[:getconfigref] 
  getconfigref( container_file, app_given  )
  exit

end



# gen manif now
gen_manifest( topo_root_dir, env_dir  ) 


exit



