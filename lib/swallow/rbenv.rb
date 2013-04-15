Capistrano::Configuration.instance(true).load do
  set :default_environment, { 'PATH' => '/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:$PATH', 'RBENV_VERSION' => ruby_version }
  set :bundle_flags, '--deployment --quiet --binstubs --shebang ruby-local-exec'

  namespace :rbenv do

    def get_rubies(version)
      rubies = {}

      find_servers.each do |server|
        rubies[server.host.to_sym] = false
      end

      run "RBENV_VERSION='' rbenv versions" do |chan, stream, data|
        host = chan[:host].to_sym
        if data.match("\s*#{version}.*")
          rubies[host] = true
        elsif !rubies.has_key? host
          rubies[host] = false
        end
      end
      rubies
    end

    desc "Install RBENV"
    task :init, :roles => :app do
      puts "  * Installing RBENV"
      run "git clone git://github.com/sstephenson/rbenv.git ~/.rbenv"
      run %{echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc}
      run %{echo 'eval "$(rbenv init -)"' >> ~/.bashrc}
      run 'mkdir -p ~/.rbenv/plugins'
      run 'git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build'
    end

    desc "Check and install the project's version of ruby if necessary."
    task :setup_ruby, :roles => :app do
      # determine if each host has the proper ruby installed
      rubies = get_rubies(ruby_version)
      skipped_rubies = rubies.clone

      # print out the skipped hosts, if any
      skipped_rubies.delete_if {|key, value| !value}
      skipped_rubies.each do |key|
        puts "  * [#{key[0]}] #{ruby_version} already installed. Skipping."
      end

      # install on the hosts without the proper ruby, if any
      rubies.delete_if{|key, val| val}
      if rubies.count > 0
        puts "  * Installing #{ruby_version}"
        rbenv.update
        run "unset RBENV_VERSION && rbenv install #{ruby_version}" do |chan, stream, data|
          if data.match(/^(Downloading|Installing|Installed) .+/)
            puts " ** [out :: #{chan[:host]}] #{data}"
          else
            puts "*** [#{stream} :: #{chan[:host]}] #{data}"
          end
        end

        rbenv.rehash
      end
    end

    desc "Calls rbenv rehash"
    task :rehash do
      run 'rbenv rehash'
    end

    desc "update rbenv"
    task :update do
      run "cd ~/.rbenv && git pull"
      run "cd ~/.rbenv/plugins/ruby-build && git pull"
      rbenv.rehash
    end
  end

  if use_rbenv
    before "deploy:setup", "rbenv:setup_ruby"
    before "deploy:update_code", "rbenv:setup_ruby"

    after "deploy:init", "rbenv:init"
    after "bundler:setup", "rbenv:rehash"
    after "bundler:install", "rbenv:rehash"
  end
end
