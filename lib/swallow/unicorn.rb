Capistrano::Configuration.instance(true).load do
  desc "Unicorn related tasks"
  namespace :unicorn do
    desc "Creates a symlink to the unicorn management script"
    task :create_symlink, :roles => :app do
      run "ln -s /etc/init.d/unicorn #{shared_path}/system/#{application}"
    end
  end
end
