Capistrano::Configuration.instance(true).load do

  if use_whenever_cron
    set :whenever_command, "cd #{release_path} && source .rvmrc && RAILS_ENV=#{rails_env} whenever"
    set :whenever_environment, env
    set :whenever_roles, :cron
    require 'whenever/capistrano'
  end

end


