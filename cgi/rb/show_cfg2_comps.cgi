#!/bin/env ruby

require 'cgi'

require 'pp'

require 'rexml/document'
include REXML


cgi = CGI.new
params = cgi.params

puts cgi.header

env_a = 'ela4';  # assuming ELA4 has the souceof-truth

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
#if File.exists?( "#{relrepo_dir}/relrepo" )
##  puts "yep... updating... "
#  update_relrepo( relrepo_dir )
#else
##  puts "not there, checking out..."
#  checkout_relrepo( relrepo_dir )
#end

#############

model_root_dir = "#{relrepo_dir}/relrepo//model/src"

container_file = model_root_dir + '/containers_OPS.xml'

puts "<h1> Components in Config 2.0 (according to container_OPS.xml in relrepo):  </h1>"


###########  defs

def parse_container_file ( file )

  config2s = Array.new()
  # container_file is an XML file
  xml = File.read( file )
  doc = REXML::Document.new( xml )

  doc.elements.each('containers/container') do |c|        
    app = c.attributes['name']
    configref = c.attributes['configRef']

    if configref 
      config2s << app
#      print app + " : "  + configref + "\n"
    end
  end

  config2s

end


config2_apps = parse_container_file( container_file )

puts "<ul>"

puts '<li>' + config2_apps.join("<li>")
puts "</ul>"

puts "# of components: ", config2_apps.size
