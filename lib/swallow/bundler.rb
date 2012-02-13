Capistrano::Configuration.instance(true).load do
  namespace :bundler do

    def get_hosts_with_bundle
      puts "Inside GHWB"
      hosts = {}
      puts "Hosts in GHWB: #{hosts}"
      begin
        run "#{source_rvmrc} && gem list | grep bundler" do |chan, stream, data|
          puts "Received #{data}"
          host = chan[:host].to_sym
          puts "Set Host #{host}"
          if data.match("\s*bundler\s+")
            hosts[host] = true
          elsif !hosts.has_key? host
            hosts[host] = false
          end
        end
      rescue e
        puts "OMFG!!!!"
        puts e.backtrace
      end
      hosts
    end

    desc "setup Bundler if it is not already setup"
    task :setup do
      if !use_rvm
        puts "  * Server does not use RVM. Skipping..."
      else
        puts "Getting Hosts..."
        hosts = get_hosts_with_bundle
        puts "Hosts: #{hosts.inspect}"
        hosts.delete_if{|key, val| val}
        if hosts.count > 0
          apps = self.roles[:app].to_ary
          apps.each_with_index do |host, i|
            run "#{source_rvmrc} && gem install bundler"
          end
        end
      end
    end

    desc "Automatically called as apart of a standard deploy."
    task :create_symlink do
      shared_dir = File.join(shared_path, 'bundle')
      release_dir = File.join(release_path, '.bundle')
      run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
    end

    desc "Automatically called as apart of a standard deploy."
    task :install do
      run "#{source_rvmrc} && bundle install RAILS_ENV=#{rails_env}" do |chan, stream, data|
        puts "  * [#{chan[:host]}] #{data}" if data.match(/^Installing/)
        puts "  * [#{chan[:host]}] #{data}" if data.match(/^Updating/)
        puts "  * [#{chan[:host]}] #{data}" if data.match(/^WARNING/)
      end

      on_rollback do
        if previous_release
          run "echo previous && #{source_rvmrc previous_release} && bundle install"
        else
          logger.important "no previous release to rollback to, rollback of bundler:install skipped"
        end
      end
    end

    desc "Automatically called as apart of a standard deploy."
    task :bundle_new_release, :roles => :app do
      bundler.create_symlink
      bundler.install
    end
  end

  after "deploy:update_code", "bundler:setup"
  after "deploy:update_code", "bundler:bundle_new_release"
end


