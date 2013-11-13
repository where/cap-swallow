Capistrano::Configuration.instance(true).load do
  namespace :deploy do
    desc "Restart Resque Workers"
    task :restart_workers, :roles => :resque do
      find_servers_for_task(current_task).each do |current_server|
        if use_resque
          puts "  * starting workers on #{current_server.host}"
          cmd = "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake resque:restart_workers[#{current_server.host}]"
          run(cmd, :hosts => current_server.host)
        end
      end
    end
  end

  before "deploy:restart_workers", "whenever:clear_crontab"
  after  "deploy:restart_workers", "whenever:update_crontab"
  after "deploy:create_symlink", "deploy:restart_workers"
end

