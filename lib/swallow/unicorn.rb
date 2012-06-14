Capistrano::Configuration.instance(true).load do
  desc "Unicorn related tasks"
  namespace :unicorn do

    desc "Creates the shared socket directory. Called after deploy:setup"
    task :setup_sockets_dir, :roles => :app do
      run "mkdir #{shared_path}/sockets"
    end

    desc "Links the tmp/sockets dir to the shared sockets dir. Called after of deploy:finalize_update"
    task :create_socket_dir, :roles => :app  do
      run "ln -s #{shared_path}/sockets #{release_path}/tmp/sockets"
    end
  end

  after "deploy:setup", "unicorn:setup_sockets_dir" if use_unicorn
  after "deploy:finalize_update", "unicorn:create_socket_dir" if use_unicorn

end
