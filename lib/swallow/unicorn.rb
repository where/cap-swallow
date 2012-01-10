Capistrano::Configuration.instance(true).load do
  desc "Unicorn related tasks"
  namespace :unicorn do
    desc "Creates a symlink to the unicorn management script"
    task :create_symlink, :roles => :app do
      run "ln -s /etc/init.d/unicorn #{shared_path}/system/#{application}"
    end

    desc "Automatically called as apart of a standard deploy. Creates the socket tmp/sockets directory"
    task :create_socket_dir, :roles => :app  do
      run "mkdir #{release_path}/tmp/sockets"
    end
  end

  after "deploy:setup", "unicorn:create_symlink" if use_unicorn

  after "deploy:finalize_update", "unicorn:create_socket_dir" if use_unicorn

end
