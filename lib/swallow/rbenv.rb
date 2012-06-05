Capistrano::Configuration.instance(true).load do
  set :default_environment, { 'PATH' => '/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:$PATH' }
  set :bundle_flags, '--deployment --quiet --binstubs --shebang ruby-local-exec'

  namespace :rbenv do

    def get_rubies(version)
      rubies = {}
      run "rbenv versions" do |chan, stream, data|
        host = chan[:host].to_sym
        if data.match("\s*#{version}\s+.*")
          rubies[host] = true
        elsif !rubies.has_key? host
          rubies[host] = false
        end
      end
      rubies
    end

    desc "Check and install the project's version of ruby if necessary."
    task :setup do
      # determine if each host has the proper ruby installed
      rubies = get_rubies(rvm_ruby)
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
          first_line = true
          run "rbenv install #{ruby_version} --with-openssl-dir=/usr/local" do |chan, stream, data|
            if first_line
              print "  * [#{host}] Installing #{ruby_version} "
              first_line = false
            end
            print '.'
          end
          run "rbenv rehash"
        end
      end

      # check that ruby was properly installed, if any installs were required
      if rubies.count > 0
        rubies = get_rubies(ruby_version).delete_if {|key, value| value}
      end

      # bail if there was an issue
      if rubies.count > 0
        puts "!!! Could not install the project's necessary ruby. Stopping deploy."
        exit 0
      end
    end
  end
end
