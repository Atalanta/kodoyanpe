require "net/ssh"
require "erb"
require "tempfile"

module Kodoyanpe

  class Provisioner
    
    def initialize
      config_path = File.expand_path("../../../config/kodoyanpe-config.rb", __FILE__)
      Kodoyanpe::Config.from_file(config_path) 
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
  
  end
  
end
