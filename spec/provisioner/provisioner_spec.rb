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

    describe "#clone_zone", :slow => true do
      it "installs a zone by cloning a pre-existing ZFS-backed zone" do
        subject.create_zone("cloned-zone", "10.10.10.103")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep cloned-zone").should match(/cloned-zone\s+configured/)
        subject.clone_zone(Config[:zone_template], "cloned-zone")
        subject.run_command("/usr/sbin/zoneadm list -vc | grep cloned-zone").should match(/cloned-zone\s+installed/)
      end
    end

    describe "#get_file" do
      it "copies a file from the remote host to the local machine" do
        local_file = subject.get_file(Config[:global_host], "/etc/release")
        File.open(local_file).grep(/Solaris/).should have_at_least(1).items 
      end
    end

    describe "#put_file" do
      it "copies a file from the local machine to the remote host" do
        Tempfile.open("put_file") do |put_file|
          put_file.puts "Test file - nothing to see here"
          put_file.flush
          subject.put_file(Config[:global_host], put_file.path, "/tmp/test_putfile")
          subject.run_command("grep 'nothing to see here' /tmp/test_putfile").should match(/nothing to see here/)
          subject.run_command("rm /tmp/test_putfile")
        end
      end
    end

    describe "#replace_line" do
      it "searches a filename for a line matching a pattern, and replaces the line with a different line" do
        Tempfile.open("test_file") do |test_file|
          test_file.puts "Linux is ok"
          test_file.puts "FreeBSD is better"
          test_file.puts "Solaris is best"
          test_file.flush
          subject.put_file(Config[:global_host], test_file.path, "/tmp/test_file")
        end
        subject.replace_line("/tmp/test_file", "^Solaris", "Solaris is best of all")
        subject.run_command("grep 'Solaris' /tmp/test_file").should match(/^Solaris is best of all$/)
        subject.run_command("wc -l /tmp/test_file").split(' ').first.should eq('3')
      end

      it "does not change a file if a pattern does not match" do
        Tempfile.open("test_file") do |test_file|
          test_file.puts "Linux is ok"
          test_file.puts "FreeBSD is better"
          test_file.flush
          subject.put_file(Config[:global_host], test_file.path, "/tmp/test_file")
        end
        subject.replace_line("/tmp/test_file", "^AIX", "AIX is best of all")
        subject.run_command("grep 'Linux' /tmp/test_file").should match(/^Linux is ok$/)
        subject.run_command("grep 'FreeBSD' /tmp/test_file").should match(/^FreeBSD is better$/)
        subject.run_command("grep 'AIX' /tmp/test_file").should match("")
        subject.run_command("wc -l /tmp/test_file").split(' ').first.should eq('2')
      end
    end
    
    describe "#start_zone" do
      it "configures and starts a newly installed zone", :slow => true do
        subject.create_zone("testzone", "10.0.0.250")
        subject.clone_zone(Config[:zone_template], "testzone")
        subject.start_zone("testzone")
        valid_ip = Regexp.new("^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$")
        lambda { Net::SSH.start("10.0.0.250", "root", :password => "omnibus") }.should_not raise_error
        result = []
        Net::SSH.start("10.0.0.250", "root", :password => "omnibus") do |session|
          session.exec!("dig +short opscode.com") do |channel, stream, data|
            result << data
          end
          result.join.should match(valid_ip)
        end
      end
    end

    describe "#upload_cookbooks" do
      it "transfers the cookbooks shipped with Kodoyanpe to the remote host"
    end

    describe "#run_chef" do
      it "runs chef-solo on the remote host" 
    end

    describe "#bootstrap" do
      it "installs Chef on a zone, and runs chef-solo" 
      # do
      #   subject.create_zone("bootstrap", "10.0.0.251")
      #   subject.clone_zone(Config[:zone_template], "bootstrap")
      #   subject.start_zone("bootstrap")
      #   subject.bootstrap("10.0.0.251")
      #   subject.run_command("chef-client --version").should match(/0.10/)
      #   subject.run_command("git --version").should match(/1.7/)
      #   subject.run_command("ruby --version").should match(/1.9/)
      # end
    end
  end
end
