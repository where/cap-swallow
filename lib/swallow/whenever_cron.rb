Capistrano::Configuration.instance(true).load do

  namespace :whenever_cron do
    task :deploy, :roles => :cron do
      if uses_whenever_cron
        set :whenever_command, "cd #{release_path} && source .rvmrc && RAILS_ENV=#{rails_env} bundle exec whenever"
        set :whenever_environment, env
        set :whenever_roles, :cron
      end
    end
  end

end


