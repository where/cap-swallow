require 'swallow/common'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

Capistrano::Configuration.instance.load do
  # User details
  _cset :user,          'deployer'
  _cset(:group)         { user }

  # Application details
  _cset(:app_name)      { abort "Please specify the short name of your application, set :app_name, 'foo'" }
  set(:application)     { "#{app_name}.mycorp.com" }
  _cset(:runner)        { user }
  _cset :use_sudo,      false
end

