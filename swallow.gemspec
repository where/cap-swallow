# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "swallow"
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bob Breznak"]
  s.date = "2011-10-27"
  s.description = "Common where cap recipies"
  s.email = "bob@where.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "config/deploy.yml",
    "lib/swallow.rb",
    "lib/swallow/assets.rb",
    "lib/swallow/bundler.rb",
    "lib/swallow/common.rb",
    "lib/swallow/deploy.rb",
    "lib/swallow/hoptoad.rb",
    "lib/swallow/rvm.rb",
    "lib/swallow/unicorn.rb",
    "lib/swallow/web.rb",
    "lib/swallow/whenever_cron.rb",
    "swallow.gemspec",
    "test/helper.rb",
    "test/test_swallow.rb"
  ]
  s.homepage = "http://github.com/where/swallow"
  s.licenses = ["MIT license"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Common where cap recipies"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<whenever>, [">= 0"])
      s.add_runtime_dependency(%q<newrelic_rpm>, [">= 0"])
      s.add_runtime_dependency(%q<rvm>, [">= 0"])
      s.add_runtime_dependency(%q<capistrano>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.3"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<whenever>, [">= 0"])
      s.add_dependency(%q<newrelic_rpm>, [">= 0"])
      s.add_dependency(%q<rvm>, [">= 0"])
      s.add_dependency(%q<capistrano>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.3"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<whenever>, [">= 0"])
    s.add_dependency(%q<newrelic_rpm>, [">= 0"])
    s.add_dependency(%q<rvm>, [">= 0"])
    s.add_dependency(%q<capistrano>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.3"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

