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

    desc "Install RVMRC"
    task :init, :roles => :app do
      first_line = true
      run "git clone git://github.com/sstephenson/rbenv.git ~/.rbenv" do |chan, stream, data|
        host = chan[:host].to_sym
        if first_line
          print "  * [#{host}] Installing RVMRC"
        else
          print '.'
        end
      end

      capture %{echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile}
      capture %{echo 'eval "$(rbenv init -)"' >> ~/.bash_profile}
      capture 'mkdir -p ~/.rbenv/plugins'
      capture 'git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build'

    end

    desc "Check and install the project's version of ruby if necessary."
    task :setup, :roles => :app do
      # determine if each host has the proper ruby installed
      rubies = get_rubies(ruby_version)
      skipped_rubies = rubies.clone

      # print out the skipped hosts, if any
      skipped_rubies.delete_if {|key, value| !value}
      skipped_rubies.each do |key|
        puts "  - [#{key}] #{ruby_version} already installed. Skipping."
      end

      # install on the hosts without the proper ruby, if any
      rubies.delete_if{|key, val| val}
      if rubies.count > 0
        apps = self.roles[:app].to_ary
        apps.each_with_index do |host, i|
          print "  * [#{host}] Installing #{ruby_version} "
          run "RBENV_VERSION='' rbenv install #{ruby_version} --with-openssl-dir=/usr/local" do |chan, stream, data|
            host = chan[:host].to_sym
            print "  * [#{host}] #{data}"
          end
          capture "rbenv rehash"
        end
      end
    end

    desc "Calls rbenv rehash"
    task :rehash do
      capture 'rbenv rehash'
    end
  end

  before "deploy:setup", "rbenv:setup" if use_rbenv

  after "bundler:setup", "rbenv:rehash" if use_rbenv
  after "bundler:install", "rbenv:rehash" if use_rbenv
end
