require "net/ssh"
require "erb"
require "tempfile"

module Kodoyanpe

  class Provisioner
    
    def initialize
      config_path = File.expand_path("../../../config/kodoyanpe-config.rb", __FILE__)
      Kodoyanpe::Config.from_file(config_path) 
    end

    def get_file(host, file)
      tempfile = Tempfile.new('get_file')
      %x[scp #{Config[:ssh_user]}@#{Config[:global_host]}:#{file} #{tempfile.path} 2>/dev/null]
      tempfile.path
    end

    def put_file(host, src, dest)
      %x[scp #{src} #{Config[:ssh_user]}@#{host}:#{dest}]
    end

    def replace_line(filename, search, replace)
      file_to_change = get_file(Config[:global_host], filename)
      re = Regexp.new(search)
      new_contents = []
      current_contents = File.new(file_to_change).readlines
      current_contents.each do |line|
        if line.match(re)
          new_contents << line.gsub!(line, replace)
        else
          new_contents << line
        end
      end
      File.open(file_to_change, "w") do |replacement|
        new_contents.each do |line|
          replacement.puts(line)
        end
        replacement.flush
      end
      put_file(Config[:global_host], file_to_change, filename)
    end

    def run_command(command)
      result = []
      Net::SSH.start( Config[:global_host], Config[:ssh_user]) do |session|
        session.exec!(command) do |channel, stream, data|
          result << data
        end
       end
      result.join
    end



    def seed_zonecfg(zonename, zoneip)
      tempfile = Tempfile.new("zonecfg")
      template = File.expand_path("../templates/zonecfg.erb", __FILE__)
      zonecfg = ERB.new(File.read(template))
      tempfile.puts zonecfg.result(binding)
      tempfile.flush
      %x[scp #{tempfile.path} #{Config[:ssh_user]}@#{Config[:global_host]}:/usr/share/zone-templates/zonecfg 2>/dev/null]
      tempfile.close
    end

    def seed_sysidcfg(zonename)
      tempfile = Tempfile.new("sysidcfg")
      template = File.expand_path("../templates/sysidcfg.erb", __FILE__)
      sysidcfg = ERB.new(File.read(template))
      tempfile.puts sysidcfg.result(binding)
      tempfile.flush
      %x[scp #{tempfile.path} #{Config[:ssh_user]}@#{Config[:global_host]}:/usr/share/zone-templates/sysidcfg 2>/dev/null]
      tempfile.close
    end    

    def create_zone(zonename, zoneip)
      seed_zonecfg(zonename, zoneip)
      seed_sysidcfg(zonename)
      run_command("/usr/sbin/zonecfg -z #{zonename} -f /usr/share/zone-templates/zonecfg")
    end

    def delete_zone(zonename)
      run_command("/usr/sbin/zonecfg -z #{zonename} delete -F")
    end

    def install_zone(zonename)
      run_command("/usr/sbin/zoneadm -z #{zonename} install")
    end

    def clone_zone(from, to)
      run_command("/usr/sbin/zoneadm -z #{to} clone #{from}")
    end

    def start_zone(zonename)
      run_command("/usr/bin/cp /usr/share/zone-templates/sysidcfg /usr/share/zones/#{zonename}/root/etc/sysidcfg")
      run_command("/usr/sbin/zoneadm -z #{zonename} boot")
      sleep(120)
      replace_line("/usr/share/zones/#{zonename}/root/etc/ssh/sshd_config", "PermitRootLogin", "PermitRootLogin yes")
      replace_line("/usr/share/zones/#{zonename}/root/etc/nsswitch.conf", "hosts:\s+files$", "hosts: files dns")
      Tempfile.open("resolver") do |resolver|
        resolver.puts "nameserver 8.8.8.8"
        resolver.puts "nameserver 8.8.4.4"
        resolver.flush
        put_file(Config[:global_host], resolver.path, "/usr/share/zones/#{zonename}/root/etc/resolv.conf")
      end
      run_command("/usr/sbin/zoneadm -z #{zonename} reboot")
    end

    def upload_cookbooks(zonename)
    end
    
    def run_chef(zonename)
    end

    def bootstrap(zonename)
      run_command("/usr/sfw/bin/wget #{Config[:packge_url]} | /usr/bin/bash")
      upload_cookbooks(zonename)
      run_chef(zonename)
    end
  end
  
end
