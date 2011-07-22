
__END__
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'capistrano'
require 'capistrano/cli'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

require 'swallow/common'

