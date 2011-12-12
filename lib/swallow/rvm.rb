Capistrano::Configuration.instance(true).load do
  desc "RVM related commands"
  namespace :rvm do

    desc "Setup the project based on the .rvmrc file"
    task :setup, :roles => :app do
      rubies = {}
      puts "Looking for #{rvm_ruby}"
      run "/usr/local/rvm/bin/rvm list" do |chan, stream, data|
        host = chan[:host].to_sym

        puts "[#{host}] - #{data}"

        if data.match("\s#{rvm_ruby}\s")
          puts "Found #{rvm_ruby} on #{host}"
          rubies[host] = true
        elsif !rubies.has_key? host
          puts "First response not find on #{host}"
          rubies[host] = false
        else
          puts "Not Found on #{host}"
        end
      end

      puts "Rubies: #{rubies.inspect}"

      #run "/usr/local/rvm/bin/rvm install #{rvm_ruby}"
    end

    task :init, :roles => :app  do
      run "rvm use #{rvm_ruby}@#{rvm_gemset} --create"

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

  before "deploy:setup", "rvm:setup"

  before "deploy:update_code", "rvm:remove_rvmrc"

  after "deploy:update_code", "rvm:create_rvmrc"
  after "deploy:update_code", "rvm:trust_rvmrc_release"
  after "deploy:update_code", "rvm:init"

  after "deploy:symlink", "rvm:trust_rvmrc_current"

end

