# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kodoyanpe/version"

Gem::Specification.new do |s|
  s.name        = "kodoyanpe"
  s.version     = Kodoyanpe::VERSION
  s.authors     = ["Stephen Nelson-Smith"]
  s.email       = ["sns@opscode.com"]
  s.homepage    = ""
  s.summary     = %q{Builds Solaris Chef-full Packages using Omnibus}
  s.description = %q{This Gem provides a command-line tool which will provision a Solaris build environment, and then build a version of Chef, together with its dependencies, and create a package.  It supports both SPARC and x86 architectures, and versions 9, 10 and 11.}

  s.rubyforge_project = "kodoyanpe"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "cucumber"
  s.add_development_dependency "rspec-expectations"
  # s.add_runtime_dependency "rest-client"
end
