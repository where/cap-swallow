Capistrano::Configuration.instance(true).load do

  if use_whenever_cron
    set :whenever_command, Proc.new { "RAILS_ENV=#{rails_env} bundle exec whenever" }
    set :whenever_environment, env
    set :whenever_roles, :cron

    require "whenever/capistrano/recipes"
    after "deploy:update_code", "whenever:update_crontab"
    after "deploy:rollback",    "whenever:update_crontab"
  end

end


