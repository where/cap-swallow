Capistrano::Configuration.instance(true).load do
  desc "RVM related commands"
  namespace :rvm do

    desc "Setup the project based on the .rvmrc file"
    task :setup, :roles => :app do
      run "echo RVM Installing #{rvm_ruby}; /usr/local/rvm/bin/rvm install #{rvm_ruby}  --with-openssl-dir=/usr/local/rvm/usr"
    end

    task :init, :roles => :app  do
      run "echo Creating Gemset #{rvm_ruby}@#{rvm_gemset}; rvm use #{rvm_ruby}@#{rvm_gemset} --create"
      require 'rvm/capistrano'
      set :rvm_ruby_string, "#{rvm_ruby}@#{rvm_gemset}"
    end

    desc "Set RVM to trust the release application's .rvmrc"
    task :trust_rvmrc_release, :roles => :app  do
      run "/usr/local/rvm/bin/rvm rvmrc trust #{release_path}"
    end

    desc "Set RVM to trust the current application's .rvmrc"
    task :trust_rvmrc_current, :roles => :app do
      run "/usr/local/rvm/bin/rvm rvmrc trust #{deploy_to}/current"
    end

    desc "Create the .rvmrc file for the project"
    task :create_rvmrc, :roles => :app  do
      run "cd #{release_path} && rvm use #{rvm_ruby}@#{rvm_gemset} --rvmrc"
    end

    desc "Remove existing rvmrc from project if it exists"
    task :remove_rvmrc do
      run "test -f #{shared_path}/cached-copy/.rvmrc && rm #{shared_path}/cached-copy/.rvmrc || true"
    end
  end

end

