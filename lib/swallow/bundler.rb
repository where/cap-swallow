Capistrano::Configuration.instance(true).load do
  namespace :bundler do

    def get_hosts_with_bundle
      hosts = {}
      run "gem list" do |chan, stream, data|
        host = chan[:host].to_sym
        if data.match("\s*bundler\s+")
          hosts[host] = true
        elsif !hosts.has_key? host
          hosts[host] = false
        end
      end
      hosts
    end

    desc "setup Bundler if it is not already setup"
    task :setup do
     hosts = get_hosts_with_bundle
     hosts.delete_if { |key, val| val }
     if hosts.count > 0
       apps = self.roles[:app].to_ary
       apps.each_with_index do |host, i|
         run "gem install bundler"
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
    task :install, :roles => :app do
      run "cd #{release_path} && (bundle check || bundle install)" do |chan, stream, data|
        puts " ** [#{stream} :: #{chan[:host]}] #{data}" if (data.match(/\S+/) && !data == ".")
      end

      on_rollback do
        if previous_release
          run "echo previous && #{previous_release} && (bundle check || bundle install)"
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


