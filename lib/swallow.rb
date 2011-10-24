unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

Dir[File.join(File.dirname(__FILE__), 'swallow/*.rb')].sort.each { |lib| require lib }

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.

