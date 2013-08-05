#!/bin/env ruby
#
# lwang: check log links for non-prod envs: beta, stg, ei1
#
require 'pp'

require 'rexml/document'
include REXML

require 'optparse'

# needs ITOPS_HOME
$itops_home = ENV['ITOPS_HOME']

unless $itops_home
  puts "You need to have ITOPS_HOME env var set."
  exit
end



def get_options()

  options = {}

  optparse = OptionParser.new do |opts| 
    opts.banner = "usage: " + __FILE__ + " [options] "

    opts.on( '-h', '--help', 'Display help screen' ) do 
      puts opts
      exit
    end
  
    options[:verbose] = false
    opts.on( '-v', '--verbose', 'Output more info' ) do
      options[:verbose] = true
    end
  
    options[:env] = nil
    opts.on( '-e', '--env ENV', 'Environment [rquired], e.g., beta, stg, ei1 ' ) do |env|
     options[:env] = env 
    end

  end
  optparse.parse!

  if options[:env] == nil
    puts optparse.help()
    exit
  end

  options

end


options = get_options()

$verbose = options[:verbose]

env_a = options[:env]


unless env_a.include?('stg') \
	or env_a.include?('beta')  \
	or env_a.include?('ei1') 

  puts "env allowed: ei1, stg, beta  "

  exit
end

env = env_a.to_s

env_dir = case env
  when 'stg'
    'STG-ALPHA'
  when 'beta'
    'STG-BETA'
  when 'ei1'
    'EI1'
end

machine_suffix = case env
  when 'stg' 
   'stg' 
  when 'beta'
    'stg'
  when 'ei1'
    'corp'
end

#puts env_dir



############ dynamically get relrepo
#relrepo_dir = '/export/content/http/i001/htdocs/lwang'
relrepo_env = ENV['RELREPO']

relrepo_dir = $1 if relrepo_env =~ /(.*)\/relrepo/

def checkout_relrepo( relrepo_dir )

  cmd = %( /usr/local/bin/svn co http://svn.corp.foobar.com:8070/svn/relrepo/network/trunk  #{relrepo_dir}/relrepo );
  system( " #{cmd} >/dev/null  2>/dev/null " )

end


def update_relrepo( relrepo_dir )

  cmd = %( /usr/local/bin/svn update    #{relrepo_dir}/relrepo );
  system( " #{cmd} >/dev/null  2>/dev/null " )

end

if File.exists?( "#{relrepo_dir}/relrepo" )
  puts "yep... updating... " if $verbose
  update_relrepo( relrepo_dir )
else
  puts "not there, checking out..." if $verbose
  checkout_relrepo( relrepo_dir )
end

#############


topo_root_dir = "#{relrepo_dir}/relrepo/topologies"
port_root_dir = '/export/content/http/i001/htdocs/cm/glu/port'
model_root_dir = "#{relrepo_dir}/relrepo//model/src"


port_file = port_root_dir + '/gen_port_' + env

container_file = model_root_dir + '/containers_OPS.xml'

puts "port_file: " + port_file if options[:verbose]

xml_dir = topo_root_dir + "/" + env_dir

puts xml_dir if options[:verbose]

d  = Dir.chdir( xml_dir )
all_xml_files = Dir.glob("*.xml")


if options[:verbose]
  puts all_xml_files.class
  puts "<p> 111"
  puts all_xml_files
  puts "<p> 222"
end



###########  defs

def get_inst_port_mapping ( port_file=nil, app=nil, mch=nil )
  mapping = Hash.new
#  port_file.rewind
  File.open(port_file).each do |line|
    line.chomp!
    if line =~ /^#{app}\/#{mch}\/(.*) : (.*)/
      mapping[$1] = $2
    end
  end
  return mapping
end


def parse_port_file ( file )

  make_hash = proc do |hash,key|
    hash[key] = Hash.new(&make_hash)
  end

  mapping = Hash.new(&make_hash)

  File.open( file ).each do | line|
    line.chomp!

    if line =~ /(.*) : (.*)/
      p1 = $1; port = $2

      if p1 =~ /(.*?)\/(.*)/
        p11 = $1; p12 = $2

        if p12 =~ /(.*)\/(.*)/
          p121 = $1; p122 = $2
#          print "33333: #{p11} ==> #{p121} ==> #{p122} ==> #{port}\n"
#          mapping[p11][p121][p122] = port
          mapping[p11] = { p121 => { p122 =>  port } }

        else
#          print "22222: #{p11} ==> #{p12} ==> #{port}\n"
#          mapping[p11][p12] = port
          mapping[p11] = {p12 => port}

        end

      else
#        print "#{p1} ==>  #{port}\n"
        mapping[p1] = port

      end
    end

  end

  return mapping

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


def update_port_file(  env )
  puts "updating port file..." if $verbose
  # $ITOPS_HOME/proj/gen_port/gen.py -p -e beta
  cmd = %( #{$itops_home}/proj/gen_port/gen.py -p -e #{env} )
  system( cmd )

end


update_port_file(  env_a )

port_of_app  = parse_port_file( port_file  )

wars_of_app = parse_container_file( container_file )

$notok_hash = {}

def check_link(app, mch_full,  url )

  # quiet
  # try once 
  # timeout=5 sec
  # no out
  cmd = %( wget -t 1  -T 5 -q -O /dev/null  #{url} )

  system( cmd )
  if $? == 0
    if $verbose
      puts "OK running #{cmd} "
    else
      print '.'
    end
  else 
    if $verbose
      puts "NOT OK running #{cmd} "
    else 
      print '.'
    end
    key = app+'  '+url
    $notok_hash[key] = 1
  end

end

##############################################
all_xml_files.to_a.sort.each do  |xml_file|

  xml = File.read(xml_file)
  doc = REXML::Document.new(xml)
  
  doc.elements.each('topology/container') do |p|
    
    app =  p.attributes['name']

    port = port_of_app.has_key?( app ) && port_of_app[app].class != Hash ? port_of_app[app] : ''

    machines_of_app = Hash.new(Array.new)
  
    p.elements.each('//entry') { |e|
      machines_of_app[app] << e.attributes['host']
    }


    ##### no need to deal with logs and jmx links for ech3

      machines_of_app[app].each  do |mch|
        mch_full = mch
        mch = mch.gsub(/\.#{machine_suffix}/, '') 
        inst_port_map  = get_inst_port_mapping( port_file, app, mch )  
  
        ##### for app, mch, k: inst, v: port
        if not inst_port_map.empty?
          inst_port_map.each_pair do |k,v|
  
              #puts  mch_full  + "(#{k},  <a href='http://#{mch_full}.foobar.com:" + inst_port_map[k] + "/logs'> logs </a> " + ")" 
  
            check_link( app, mch_full, "http://#{mch_full}.foobar.com:" + inst_port_map[k] + "/logs" )
          end
        else
  
          if app.include? '-tomcat' or app == 'lmt'

            if app == 'firehose-tomcat'

              #puts mch_full + "( <a href='http://#{mch_full}.foobar.com:" + '12900' + '/' + 'sharing-firehose-frontend' + "/logs'> logs </a> " + " )" 
              check_link( app, mch_full,   "http://#{mch_full}.foobar.com:" + '12900' + '/' + 'sharing-firehose-frontend' + "/logs" )

            else

              #puts mch_full + "( <a href='http://#{mch_full}.foobar.com:" + '12900' + '/' + app.sub('-tomcat','') + "/logs'> logs </a> " + ")" 
              check_link( app, mch_full, "http://#{mch_full}.foobar.com:" + '12900' + '/' + app.sub('-tomcat','') + "/logs" )

            end

          else

            #puts mch_full + "( <a href='http://#{mch_full}.foobar.com:" + port + "/logs'> logs </a> " + " )" 
            check_link( app, mch_full, "http://#{mch_full}.foobar.com:" + port + "/logs" )

          end
  
        end

      end
  


  end
  
end

puts 
puts "NOT OKs:"
$notok_hash.keys.sort.each { |k|
  puts k
}

