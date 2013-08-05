#!/bin/env ruby
#
# lwang: compare configs (extservices.springconfig)
#
require 'optparse'
require 'rexml/document'
include REXML
require 'net/http'
require 'pp'


def get_options()

  options = {}

  optparse = OptionParser.new do |opts|

    opts.banner = "usage: " + __FILE__ + " [options] "


    opts.on( '-h', '--help', 'Display help screen') do
      puts opts
      exit
    end

    options[:verbose] = false
    opts.on('-v', '--verbose', 'Output more info') do
      options[:verbose] = true
    end

    options[:ver] = nil
      opts.on( '-v', '--ver VER', 'Version# [required] , e.g., 520' ) do |ver|
      options[:ver] = ver
    end

    options[:ver1] = nil
      opts.on( '-v', '--ver1 VER1', 'Version#, e.g., 520' ) do |ver1|
      options[:ver1] = ver1
    end

    options[:ver2] = nil
      opts.on( '-v', '--ver2 VER2', 'Version#, e.g., 520' ) do |ver2|
      options[:ver2] = ver2
    end

    options[:ccsdirname] = nil
      opts.on( '-c', '--ccsdirname CCSDIRNAME', 'CCS dir name, e.g., auth rather than auth-server' ) do |ccsdirname|
      options[:ccsdirname] = ccsdirname
    end
 
    options[:debug] = false
    opts.on('-d', '--debug', 'Output debug info') do
      options[:debug] = true
    end

    options[:env1] = nil
      opts.on( '-e', '--env1 ENV1', 'Environment 1 [required], e.g., ei1, beta, stg, ech3 ' ) do |env1|
      options[:env1] = env1
    end

    options[:env2] = nil
      opts.on( '-e', '--env2 ENV2', 'Environment 2 [required] ' ) do |env2|
      options[:env2] = env2
    end


 
  end
  optparse.parse!


  if options[:env1] == nil or options[:env2] == nil and ( options[:ver] == nil or ( options[:ver1] == nil and options[:ver2] == nil ) )
    puts optparse.help()
    exit
  end


  options 

end




def parse_xml_file( xml_file )

  h = Hash.new

  xml = File.read( xml_file )
  doc = REXML::Document.new(xml)

  doc.elements.each('//constructor-arg') do |root|
    root.elements.each('//entry') {  |e|
      key = e.attributes['key']
      value = e.attributes['value']
      unless  key.empty?  and value.empty?
        h[key] = value
      end
    }
  end

  h

end


def get_ccs_host( env=nil )

  warn "I need an env." unless env
  case env
    when 'beta', 'stg'  then 'esv4-be05.stg'
    when 'ech3' then 'ech3-cfg02.prod'
    when 'ei1' then 'esv4-be29.corp'
  end

end



def get_ccs_root_dir( env=nil )

  warn "I need an env." unless env
  case env
    when 'ech3' then '/export/content/master_repository/PROD-ECH3'
    when 'beta' then '/export/content/repository/STG-BETA'
    when 'stg' then '/export/content/repository/STG-ALPHA'
    when 'ei1' then '/export/content/repository/EI1'
  end

end


def get_app_conf_base_uri ( env=nil )

  warn "I need an env." unless env
  case env
    when 'ech3' then 'http://ech3-cfg-vip-a.prod:10093/configuration/get/PROD-ECH3'
    when 'beta' then 'http://esv4-be05.stg:10093/configuration/get/STG-BETA'
    when 'stg' then 'http://esv4-be05.stg:10093/configuration/get/STG-ALPHA'
    when 'ei1' then 'http://esv4-be29.corp:10093/configuration/get/EI1'
  end

end


def get_xml_str(env, app, ver)

  url_base = get_app_conf_base_uri( env )
  url_to_parse = url_base + '/' + app + '/' + '0.0.' + ver + '/extservices.springconfig'

#  puts url_to_parse 

  url = URI.parse( url_to_parse )
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.start(url.host, url.port) { |http|
    http.request(req)
  }
  
  res.body

end


def parse_xml_str( xmlstr )

  h = {}

  doc = Document.new xmlstr

  doc.elements.each("//entry") do  |element| 

    key = element.attributes['key']
    val = element.attributes['value']

    h[key] = val

  end

  h

end


def analyze( h1, h2, env1, env2, ccsdirname, ver, options )

  keys1 = h1.keys.sort.uniq
  keys2 = h2.keys.sort.uniq

  keys_in_1_not_in_2 = keys1 - keys2
  keys_in_2_not_in_1 = keys2 - keys1
  keys_in_both = keys1 & keys2

  if options[:verbose] 

    puts
    puts "===== Keys found in #{env1}/#{ccsdirname}/#{ver} but not in #{env2}/#{ccsdirname}/#{ver}"
    unless keys_in_1_not_in_2.empty?
      puts  keys_in_1_not_in_2
    else
      puts "\tNone" 
    end
  
    puts
    puts "===== Keys found in #{env2}/#{ccsdirname}/#{ver} but not in #{env1}/#{ccsdirname}/#{ver}"
    unless keys_in_2_not_in_1.empty?
      puts keys_in_2_not_in_1
    else
      puts  "\tNone" 
    end
  
    has_value_diff = nil
    puts
    puts "===== Value diff for keys in #{env1}/#{ccsdirname}/#{ver} and #{env2}/#{ccsdirname}/#{ver}" 
    keys_in_both.each do |k|
      unless h1[k].to_s == h2[k].to_s
        has_value_diff = true
        puts  k.to_s + "\n\t" + h1[k].to_s + "\n\t" + h2[k].to_s
      end
    end
    unless has_value_diff
      puts  "\tNone"
    end
  
  end 

  if keys_in_1_not_in_2.empty? and  keys_in_2_not_in_1.empty? and has_value_diff == nil
    return 0
  else
    return 1
  end


end


def analyze_2( h1, h2, env1, env2, ccsdirname, ver1, ver2, options )

  keys1 = h1.keys.sort.uniq
  keys2 = h2.keys.sort.uniq

  keys_in_1_not_in_2 = keys1 - keys2
  keys_in_2_not_in_1 = keys2 - keys1
  keys_in_both = keys1 & keys2

  if options[:verbose] 

    puts
    puts "===== Keys found in #{env1}/#{ccsdirname}/#{ver1} but not in #{env2}/#{ccsdirname}/#{ver2}"
    unless keys_in_1_not_in_2.empty?
      puts  keys_in_1_not_in_2
    else
      puts "\tNone" 
    end
  
    puts
    puts "===== Keys found in #{env2}/#{ccsdirname}/#{ver2} but not in #{env1}/#{ccsdirname}/#{ver1}"
    unless keys_in_2_not_in_1.empty?
      puts keys_in_2_not_in_1
    else
      puts  "\tNone" 
    end
  
    has_value_diff = nil
    puts
    puts "===== Value diff for keys in #{env1}/#{ccsdirname}/#{ver1} and #{env2}/#{ccsdirname}/#{ver2}" 
    keys_in_both.each do |k|
      unless h1[k].to_s == h2[k].to_s
        has_value_diff = true
        puts  k.to_s + "\n\t" + h1[k].to_s + "\n\t" + h2[k].to_s
      end
    end
    unless has_value_diff
      puts  "\tNone"
    end
  
  end 

  if keys_in_1_not_in_2.empty? and  keys_in_2_not_in_1.empty? and has_value_diff == nil
    return 0
  else
    return 1
  end


end


def get_apps_with_given_ver( env1, ver, options ) 

  ccs_host = get_ccs_host( env1 )

  ccs_root_dir = get_ccs_root_dir( env1 )

  cmd_scp = %( /bin/scp worker.sh #{ccs_host}:~  2>/dev/null)
  puts "INFO: getting worker over."  if options[:verbose]
  system( cmd_scp )

  cmd_ssh = %( /bin/ssh #{ccs_host} ' ~/worker.sh #{ccs_root_dir} #{ver}; /bin/rm ~/worker.sh ' 2>/dev/null)
  apps = %x( #{cmd_ssh} )

  # apps.class = String
  apps.split("\n")

end

def do_it_for_given_app( env1, env2,  ccsdirname,  ver, options )

    xml_str_1 = get_xml_str( env1, ccsdirname,  ver)
    h1 =  parse_xml_str( xml_str_1 )
    
    xml_str_2 = get_xml_str( env2, ccsdirname, ver )
    h2 =  parse_xml_str( xml_str_2 )
    
    
    if options[:debug]
      PP.pp h1
      puts "========"
      PP.pp h2
    end
    
    analyze( h1, h2, env1, env2,  ccsdirname, ver, options )

end


def do_it_for_given_app_2( env1, env2,  ccsdirname,  ver1, ver2, options )

    xml_str_1 = get_xml_str( env1, ccsdirname,  ver1)
    h1 =  parse_xml_str( xml_str_1 )
    
    xml_str_2 = get_xml_str( env2, ccsdirname, ver2 )
    h2 =  parse_xml_str( xml_str_2 )
    
    
    if options[:debug]
      PP.pp h1
      puts "========"
      PP.pp h2
    end
    
    analyze_2( h1, h2, env1, env2,  ccsdirname, ver1, ver2,  options )

end




def main

  options = get_options()
  
  env1 = options[:env1]
  env2 = options[:env2]
  ver = options[:ver]
  ver1 = options[:ver1]
  ver2 = options[:ver2]
  ccsdirname = options[:ccsdirname]

  if options[:debug] 
  
    puts "env1: " + env1 if env1
    puts "env2: " + env2 if env2
    puts "ver: " + ver if ver
    puts "ver1: " + ver1 if ver1
    puts "ver2: " + ver2 if ver2
    puts "ccsdirname: " + ccsdirname if ccsdirname

  end

  unless  ccsdirname == nil

    if ver1 and ver2 

      ret_code = do_it_for_given_app_2( env1, env2,  ccsdirname,  ver1, ver2, options )

    elsif ver

      ret_code = do_it_for_given_app( env1, env2,  ccsdirname,  ver, options )

    else

      warn "either give me --ver VER or give me --ver1 VER1 --ver2 VER2"
      exit

    end

  else

    if ver1 and ver2
      warn "Oops, you need to provide --ccsdirname CCSDIRNAME since you provded --ver1 VER1 and --ver2 VER2"
      exit
    end

    apps_with_given_ver = get_apps_with_given_ver( env1, ver, options )

    puts apps_with_given_ver if options[:debug]

    apps_with_given_ver.each do |app|

      # do for each app
      ret_code = do_it_for_given_app( env1, env2,  app,  ver, options )      
#      puts "do it for #{env1} #{env2} #{app} #{ver}"

    end

  end

  puts "ret_code = " + ret_code.to_s if options[:debug]
  ret_code

end




if $0 == __FILE__
  exit main()
end



