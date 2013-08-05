module MYCM

  @@itops_home = ENV['ITOPS_HOME']

  ######## 
  def self.get_itops_home

    @@itops_home

  end

  ######## 
  def self.get_manif_file_of ( env )

    itops_home = get_itops_home
    manif_file =  itops_home + "/manif/manifest_" + env

  end

  ######## 
  def self.get_container_mapping_file_of ( env )

    itops_home = get_itops_home
    itops_home + "/manif/container_mapping_" + env

  end


  ######## 
  # all boxes in manifest 
  def self.get_hosts_of_ ( env, as='str', app='all' )

    manif_file = get_manif_file_of(env)

    hosts = []
    File.open(manif_file).each_line do |line|
      line.chomp
#        hosts << $1.split(/\s+/) 
      if line =~ /.*\t(.*)/
        $1.split(/\s+/).each { |s|
          hosts.push(s)
        }
      end
    end

    uniq_hosts  = hosts.sort.uniq
    as == 'str' ? uniq_hosts.join(" ") : uniq_hosts

  end

  ######## 
  # excluding memcache boxes
  def self.get_hosts_of ( env, as='str', app='all' )

    manif_file = get_manif_file_of(env)

    hosts = [] 
    File.open(manif_file).each_line do |line|
      line.chomp
      if line.match(/(.*)\t(.*)/) 
        app = $1
        boxes = $2
        unless app =~ /memcache/
          boxes.split(/\s+/).each { |s|
            hosts.push(s)
          }
        end
      end
    end

    uniq_hosts  = hosts.sort.uniq
    as == 'str' ? uniq_hosts.join(" ") : uniq_hosts

  end

  ######## 
  # all boxes in manifest for a given app
  def self.get_hosts_of_app ( env, as='str', app_given=nil )

    warn "I need an app given." unless app_given
    manif_file = get_manif_file_of(env)

    hosts = []
    File.open(manif_file).each_line do |line|
      line.chomp
      if line =~ /^#{app_given}\t(.*)/
        $1.split(/\s+/).each { |s|
          hosts.push(s)
        }
      end
    end

    uniq_hosts  = hosts.sort.uniq
    as == 'str' ? uniq_hosts.join(" ") : uniq_hosts

  end


  ######## 
  # get_installed_dir
  def self.get_installed_dir ( env='ech3', app_given=nil )

    warn "I need an app given." unless app_given
    container_mapping_file = get_container_mapping_file_of(env)

    File.open(container_mapping_file).each_line do |line|
      line.chomp
      if line =~ /^#{app_given}\t(.*)/
        return $1  # if found in container_mapping file, use it
      end
    end

    app_given  # if not found in container_mapping file, return app_given

  end

  ######## 
  # is_frontend?
  def self.is_frontend? ( env='ech3', app_given=nil ) 

    warn "I need an app given." unless app_given
    container_mapping_file = get_container_mapping_file_of(env)
  
    File.open(container_mapping_file).each_line do |line|
      line.chomp
      if line =~ /^#{app_given}\t/
        return 'is_frontend'
      end
    end

    # if we are here, it means the app_given is NOT frontend
    nil

  end

  ######## 
  # get_all_apps_of
  def self.get_all_apps_of ( env=nil, as='str' )
  
    warn "I need an env." unless env
    manif_file = get_manif_file_of(env)

    apps = []
    File.open(manif_file).each_line do |line| 
      line.chomp
      if line =~ /(.*)\t.*/
        apps << $1
      end
    end

    uniq_apps = apps.sort.uniq
    as == 'str' ? uniq_apps.join(" ") : uniq_apps

  end
  

end


###################
if $0 == __FILE__
  puts MYCM.get_itops_home
#  puts MYCM.get_manif_file_of('beta')
#  puts MYCM.get_hosts_of('ech3', 'array')
  puts
#  puts MYCM.get_hosts_of_app('ech3', 'array', 'rate-limit')
#  puts MYCM.get_hosts_of_app('ech3', 'array', 'cloud-session')
#  puts MYCM.get_hosts_of('ech3')
#  puts MYCM.get_installed_dir('ech3', 'leo')
#  puts MYCM.get_all_apps_of('ech3', 'array')

  if MYCM.is_frontend?( ARGV[0], ARGV[1] )
    puts "is FE"
  else
    puts "is NOT FE"
  end

end
