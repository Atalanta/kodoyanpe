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

When /^I run the command$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I specify "([^"]*)" as the architecture$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

When /^I specify "([^"]*)" as the version$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^I should get a package of the latest Chef client accessible from my workstation$/ do
  pending # express the regexp above with the code you wish you had
end
