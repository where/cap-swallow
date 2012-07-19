Capistrano::Configuration.instance(true).load do
  namespace :deploy do
    desc "Restart Resque Workers"
    task :restart_workers, :roles => :daemon do
       run "#{source_rvmrc} && RAILS_ENV=#{rails_env} bundle exec rake resque:restart_workers" if use_resque
    end
  end
  
  after "deploy", "deploy:restart_workers"
end

