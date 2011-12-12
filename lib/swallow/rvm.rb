Capistrano::Configuration.instance(true).load do
  desc "RVM related commands"
  namespace :rvm do

    def get_rubies(ruby_version)
      rubies = {}
      run "/usr/local/rvm/bin/rvm list" do |chan, stream, data|
        host = chan[:host].to_sym
        if data.match("\s*#{ruby_version}\s+")
          rubies[host] = true
        elsif !rubies.has_key? host
          rubies[host] = false
        end
      end
      rubies
    end

    desc "Initial rvm setup for a completely fresh server"
    task :init do
      first_line = true
      run "/usr/local/rvm/bin/rvm pkg install openssl" do |chan, stream, data|
        if first_line
          print "  * [#{host}] Installing openssl pkg "
          first_line = false
        end
        print '.'
      end
    end

    desc "Check and install the project's version of ruby (based on rvm_ruby) if its not already installed."
    task :setup do
      rubies = get_rubies(rvm_ruby)
      apps = self.roles[:app].to_ary
      apps.each_with_index do |host, i|
        if !rubies[host.to_s.to_sym]
          first_line = true
          run "/usr/local/rvm/bin/rvm install #{rvm_ruby} --with-openssl-dir=/usr/local/rvm/usr" do |chan, stream, data|
            if first_line
              print "  * [#{host}] Installing #{rvm_ruby} "
              first_line = false
            end
            print '.'
          end
        else
          puts "  - [#{host}] #{rvm_ruby} already installed. Skipping."
        end
      end

      rubies.delete_if {|key, value| value}
      if rubies.count > 0
        rubies = get_rubies(rvm_ruby).delete_if {|key, value| value}
      end

      if rubies.count > 0
        puts "!!! Could not install the project's necessary ruby. Stopping deploy."
        exit 0
      end

    end

    task :set_gemset, :roles => :app  do
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
  after "deploy:update_code", "rvm:set_gemset"

  after "deploy:symlink", "rvm:trust_rvmrc_current"

end

