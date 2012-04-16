Given /^a copy of the kodoyanpe tool$/ do
  project_root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
  pkg_dir = project_root.join('pkg')
  rakefile = File.join(project_root, 'Rakefile')
  built_gems = File.join(pkg_dir, '*.gem')
  latest = Dir.glob(built_gems).sort {|a, b| File.ctime(a) <=> File.ctime(b) }.last
  File.exist?(rakefile).should be_true
  silent_system('rake build').should be_true
  silent_system("gem install #{latest} --no-ri --no-rdoc").should be_true
  silent_system("which kodoyanpe").should be_true
end


When /^I run the command without options$/ do
  @help_text = %x[kodoyanpe]
end

Then /^I see some help text$/ do
  @help_text.include?("Kodoyanpe builds Chef-full packages for Solaris").should be_true
end

Given /^these options:$/ do |table|
  @options = Hash[*[table.raw]]
end

When /^I run kodoyanpe$/ do
  silent_system("kodoyanpe --arch #{@options["architecture"]} --solaris-release #{@options["solaris-release"]}")
end

Then /^I should get a package of the latest Chef client accessible from my workstation$/ do
  find_package(@options["architecture"], @options["solaris-version"]).should be_true
end
