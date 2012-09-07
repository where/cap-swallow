# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "cap-swallow"
  gem.homepage = "http://github.com/where/swallow"
  gem.license = "MIT license"
  gem.summary = %Q{Common where cap recipies}
  gem.description = %Q{Common where cap recipies}
  gem.email = "bob@where.com"
  gem.authors = ["Bob Breznak"]
end
Jeweler::RubygemsDotOrgTasks.new

