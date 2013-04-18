Capistrano::Configuration.instance(true).load do
  namespace :deploy do
    desc "Restart Resque Workers"
    task :restart_workers, :roles => :resque do
      find_servers_for_task(current_task).each do |current_server|
        puts "starting workers on #{current_server.host}"
        run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake resque:restart_workers[#{current_server.host}]" if use_resque
      end
    end
  end

  after "deploy:create_symlink", "deploy:restart_workers"
end

