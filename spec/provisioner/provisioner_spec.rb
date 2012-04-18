require 'spec_helper'

module Kodoyanpe
  describe Provisioner do
    describe "#run_command" do
      it "connects to a zone host and runs a zone-based command" do
        subject.run_command("zonename").should match(/global/)
      end
    end
    
    describe "#seed_zonecfg" do
      it "renders a zonecfg response file on the global zone" do
        subject.seed_zonecfg("rspec", "10.10.10.100")
        subject.run_command("grep 10.10.10.100 /usr/share/zone-templates/zonecfg").should match(/10.10.10.100/)
        subject.run_command("grep rspec /usr/share/zone-templates/zonecfg").should match(/rspec/)
      end
    end

    describe "#seed_sysidcfg" do
      it "renders a sysidcfg file on the global zone" do
        subject.seed_sysidcfg("rspec")
        subject.run_command("grep rspec /usr/share/zone-templates/sysidcfg").should match(/rspec/)
      end
    end

    describe "#create_zone" do
      it "creates a Solaris zone" do
        subject.create_zone("rspec", "10.10.10.100")
        subject.run_command("/usr/sbin/zonecfg -z rspec info net | grep address").should match(/10.10.10.100/)
        subject.run_command("/usr/sbin/zonecfg -z rspec info zonename | grep rspec").should match(/rspec/)
        subject.run_command("/usr/sbin/zoneadm list -vc | grep rspec").should match(/rspec\s+configured/)
      end
    end

    describe "#delete_zone" do
      it "deletes an existing zone" do
        subject.create_zone("to-be-deleted", "10.10.10.101")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep to-be-deleted").should match(/to-be-deleted/)
        subject.delete_zone("to-be-deleted")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep to-be-deleted").should_not match(/to-be-deleted/)
        subject.run_command("/usr/sbin/zonecfg -z to-be-deleted info").should match(/No such zone configured/)        
      end
    end

    describe "#install_zone" do
      it "installs a zone", :slow => true do
        subject.create_zone("installed-zone")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep installed-zone").should match(/installed-zone\s+configured/)
        subject.install_zone("installed-zone")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep installed-zone").should match(/installed-zone\s+installed/)
      end
    end

    describe "#clone_zone" do
      it "installs a zone by cloning a pre-existing ZFS-backed zone" do
        subject.create_zone("cloned-zone", "10.10.10.103")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep cloned-zone").should match(/cloned-zone\s+configured/)
        subject.clone_zone(Config[:zone_template], "cloned-zone")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep cloned-zone").should match(/cloned-zone\s+installed/)
      end
    end

    describe "#start_zone" do
      it "configures and starts a newly installed zone" do
        subject.create_zone("test-zone", "10.10.10.104")
        subject.clone_zone(Config[:zone_template], "test-zone")
        subject.start_zone("test-zone")
        lambda { Net::SSH.start("10.10.10.104", "root", :password => "omnibus") }.should_not raise_error
        lambda { Net::SSH.start( Config[:global_host], Config[:ssh_user]) do |session|
            session.exec!("dig +short opscode.com") do |channel, stream, data|
              result << data
            end
          end
          result.join }.should match(/^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/)
      end
      
    end
  end
end
