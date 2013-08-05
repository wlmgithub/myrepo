#!/bin/env ruby

require 'cgi'

require 'pp'

require 'rexml/document'
include REXML


cgi = CGI.new
params = cgi.params

puts cgi.header

env_a = params['env']
svc = params['svc']    # given a svc name, return a space separated string of hosts for the service

# Bruno requests: &getsvcs  : to get a list of services
# Bruno requests: &host=hostname : to get all services running on hostname
getsvcs = params['getsvcs']
host = params['host']

# ewong requested it, i need it too :)
gethosts = params['gethosts']


http_host = ENV['HTTP_HOST']
script_name = ENV['SCRIPT_NAME']

unless env_a.include?('stg') \
	or env_a.include?('beta')  \
	or env_a.include?('ech3') \
	or env_a.include?('ei1')  \
	or env_a.include?('ei3') \
	or env_a.include?('ela4') 

#  puts "env allowed: ei1, stg, beta, or ech3 <p />"

  puts <<MSG;

Options: <p />

http://#{http_host}/#{script_name}?gethosts&env=&lt;your_env&gt; <br />  -- get all hosts in your_env <p /> 
http://#{http_host}/#{script_name}?getsvcs&env=&lt;your_env&gt; <br />  -- get all services in your_env <p /> 
http://#{http_host}/#{script_name}?svc=&lt;your_svc&gt;&env=&lt;your_env&gt; <br />  -- get all hosts running your_svc in your_env <p /> 
http://#{http_host}/#{script_name}?host=&lt;your_host&gt;&env=&lt;your_env&gt; <br />  -- get all services running on your_host in your_env <p /> 

<p>
where: <p>
<ul>
<li> &lt;your_env&gt; includes: ei1, ei3, ela4,  stg, beta, or ech3     
<li> &lt;your_svc&gt; is like: cloud, auth-server etc.
<li> &lt;your_host&gt; is like esv4-be02.stg, ech3-be10.prod etc.
</ul>


MSG

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


############ dynamically get relrepo
relrepo_dir = '/export/content/http/i001/htdocs/lwang'

def checkout_relrepo( relrepo_dir )

  cmd = %( /usr/local/bin/svn co http://svn.corp.foobar.com:8070/svn/relrepo/network/trunk  #{relrepo_dir}/relrepo );
  system( " #{cmd} >/dev/null  2>/dev/null " )

end


def update_relrepo( relrepo_dir )

  cmd = %( /usr/local/bin/svn update    #{relrepo_dir}/relrepo );
  system( " #{cmd} >/dev/null  2>/dev/null " )

end

######## we have a cronjob running under 'web' every 15 minutes to update relrepo, so no need to do this check anymore
# 0,15,30,45 * * * * /usr/local/bin/svn update /export/content/http/i001/htdocs/lwang/relrepo >/dev/null 2>&1
#if File.exists?( "#{relrepo_dir}/relrepo" )
##  puts "yep... updating... "
#  update_relrepo( relrepo_dir )
#else
##  puts "not there, checking out..."
#  checkout_relrepo( relrepo_dir )
#end

#############


#topo_root_dir = '/export/content/http/i001/htdocs/cm/glu/topologies'
#port_root_dir = '/export/content/http/i001/htdocs/cm/glu/port'
#model_root_dir = '/export/content/http/i001/htdocs/cm/glu/model/src'

topo_root_dir = "#{relrepo_dir}/relrepo/topologies"
port_root_dir = '/export/content/http/i001/htdocs/cm/glu/port'
model_root_dir = "#{relrepo_dir}/relrepo//model/src"


port_file = port_root_dir + '/gen_port_' + env

container_file = model_root_dir + '/containers_OPS.xml'

#puts "port_file: " + port_file

xml_dir = topo_root_dir + "/" + env_dir

#puts xml_dir

d  = Dir.chdir( xml_dir )
all_xml_files = Dir.glob("*.xml")

#puts all_xml_files.class
#puts "<p> 111"
#puts all_xml_files
#puts "<p> 222"

if not svc.empty?

  all_xml_files.to_a.sort.each do |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)

    doc.elements.each('topology/container') do |p|
      app = p.attributes['name']
      if app == svc.to_s
        machines_of_app = Hash.new(Array.new)
        p.elements.each('//entry') { |e|
          machines_of_app[app] << e.attributes['host']
        }
        print machines_of_app[app].join(" ") 
      end
    end
  end

  exit
end   ##### end the svc != nil section

if not getsvcs.empty?
 
  all_xml_files.to_a.sort.each do |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)

    doc.elements.each('topology/container') do |p|
      app = p.attributes['name']
      puts app 
#      print app + "<br />"
    end
  end

  exit
  
end  ##### end case for getsvcs


if not gethosts.empty?
 
  all_hosts = []
  all_xml_files.to_a.sort.each do |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)

    doc.elements.each('//entry') do |p|
      all_hosts <<  p.attributes['host']
#      puts h
#      print app + "<br />"
    end
  end

  puts all_hosts.sort.uniq

  exit
  
end  ##### end case for gethosts



if not host.empty?

  apps_of_machine = Hash.new(Array.new)

  all_xml_files.to_a.sort.each do |xml_file|
  
    xml = File.read(xml_file)
    doc = REXML::Document.new(xml)

    doc.elements.each('topology/container') do |p|
      app = p.attributes['name']
      p.elements.each('//entry') { |e|
        h = e.attributes['host']
        if host.to_s == h
          apps_of_machine[host] << app
        end
      }
    end
  end
  puts apps_of_machine[host].join(" ")

  exit

end ##### end case for host


puts "<h1> Showing Manifest for " +  env_dir+ " (GLU) </h1>"
puts "<table border=1>"
puts "<tr bgcolor='green'><th> Application  </th>  <th> Port  </th> <th> War(s) </th>  <th> Machines </th></tr> "


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


def get_port_v2( app, port_file )
  # nested hash: mapping :   
  #	app=>port
  #	app=>mch=>port
  #	app=>mch=>inst=>port
  #
  mapping = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

  port_array = []
  File.open(port_file).each_line do |line|
    line.chomp
    if line.match(/(.*) : (.*)/)
      a = $1
      p = $2
      if a == app
        port_array << p
        mapping[a] = p
      elsif line.match(/(.*?)\/(.*) : (.*)/)
        if $1 == app
          port_array << $3
          mapping[$1][$2] = $3
        end          
      elsif line.match(/(.*?)\/(.*?)\/(.*) : (.*)/)
        if $1 == app
          port_array << $4
          mapping[$1][$2][$3] = $4
        end          
      else
        next
      end
    end
  end



##### just want to see mapping
puts "<pre>"
  PP.pp(mapping)
puts "</pre>"

  if port_array
#     port_array.sort.uniq.join(' ')
     port_array.join(' ')
  else
    return ' '
  end
end


def get_port( app, port_file )
  port_array = []
  File.open(port_file).each_line do |line|
    line.chomp
    if line.match(/(.*) : (.*)/)
      a = $1
      p = $2
      if a == app
        port_array << p
      elsif line.match(/(.*?)\/(.*) : (.*)/)
        if $1 == app
          port_array << $3
        end          
      elsif line.match(/(.*?)\/(.*?)\/(.*) : (.*)/)
        if $1 == app
          port_array << $4
        end          
      else
        next
      end
    end
  end

  if port_array
#     port_array.sort.uniq.join(' ')
     port_array.join(' ')
  else
    return ' '
  end
end
###########  


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

port_of_app  = parse_port_file( port_file  )

wars_of_app = parse_container_file( container_file )


=begin

puts '<br>33333333333<br>'
puts '<pre>'
pp(wars_of_app['abook'])
puts '</pre>'


puts '<br>33333333333<br>'
puts '<pre>'
pp(port_of_app['data-platform-storage'])
puts '</pre>'
puts '4444444444<br>'
pmap = get_inst_port_mapping( port_file, 'invitations', 'esv4-be38')
pp(pmap)
puts '555555555<br>'
=end


all_xml_files.to_a.sort.each do  |xml_file|

  #puts xml_file

  xml = File.read(xml_file)
  doc = REXML::Document.new(xml)
  
  doc.elements.each('topology/container') do |p|
    
    app =  p.attributes['name']
#    port =  get_port(app, port_file) 
    

     port = port_of_app.has_key?( app ) && port_of_app[app].class != Hash ? port_of_app[app] : ''

    wars = wars_of_app.has_key?( app ) && wars_of_app[app].class != Hash ? wars_of_app[app] : []

    machines_of_app = Hash.new(Array.new)

#    print app + " : " + port 
#    print app + " : "
    print "<tr> <td> " + app + "</td> "
    print " <td> " + port.to_s + "</td> "

    print " <td> " + wars.join(' ') + "</td> "

  
#    p.elements.each { |e|
#      puts e.attributes['host']
#    }
  
    puts "<td>"
    p.elements.each('//entry') { |e|
#      puts e.attributes['host']
      machines_of_app[app] << e.attributes['host']
    }


    ##### no need to deal with logs and jmx links for ech3
    if env == 'ech3' or env == 'ela4'

      puts machines_of_app[app]

    else

      machines_of_app[app].each  do |mch|
  #      puts mch + "( <a href='http://#{mch}:/logs'> logs </a> )"
  #      puts "===#{app} : #{env} #{mch}==="
        mch_full = mch
        mch = mch.gsub(/\.#{machine_suffix}/, '') 
        inst_port_map  = get_inst_port_mapping( port_file, app, mch )  
  
        ##### for app, mch, k: inst, v: port
        if not inst_port_map.empty?
  #        inst_port_map.each_pair { |k,v| puts  "(#{k} #{v})" }
          inst_port_map.each_pair do |k,v|
  
              puts  mch_full  + "(#{k},  <a href='http://#{mch_full}.foobar.com:" + inst_port_map[k] + "/logs'> logs </a> ," + "<a href='http://#{mch_full}.foobar.com:" + inst_port_map[k] + "/jmx'> jmx </a> )" 
  
          end
        else
  
          if app.include? '-tomcat' or app == 'lmt'

            if app == 'firehose-tomcat'

              puts mch_full + "( <a href='http://#{mch_full}.foobar.com:" + '12900' + '/' + 'sharing-firehose-frontend' + "/logs'> logs </a> ," + "<a href='http://#{mch_full}.foobar.com:" + '12001' + "/jmx'> jmx </a> )" 

            else

              puts mch_full + "( <a href='http://#{mch_full}.foobar.com:" + '12900' + '/' + app.sub('-tomcat','') + "/logs'> logs </a> ," + "<a href='http://#{mch_full}.foobar.com:" + '12001' + "/jmx'> jmx </a> )" 

            end

          else

            puts mch_full + "( <a href='http://#{mch_full}.foobar.com:" + port + "/logs'> logs </a> ," + "<a href='http://#{mch_full}.foobar.com:" + port + "/jmx'> jmx </a> )" 
          end
  
        end
  
      end


    end


    puts "</td>"

    puts "</tr>"
  
  end
  
end

puts "</table>"




