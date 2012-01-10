Capistrano::Configuration.instance(true).load do

  if use_whenever_cron
    set :whenever_command, Proc.new { "#{source_rvmrc} && RAILS_ENV=#{rails_env} bundle exec whenever" }
    set :whenever_environment, env
    set :whenever_roles, :cron
    require 'whenever/capistrano'
  end

end


