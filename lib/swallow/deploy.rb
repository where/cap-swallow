Capistrano::Configuration.instance(true).load do

  require 'rubygems'
  require 'json'
  require 'new_relic/recipes'

  namespace :deploy do
    task :start do
      run "RAILS_ENV=#{rails_env} #{shared_path}/system/#{application} start"
    end

    task :stop do
      run "RAILS_ENV=#{rails_env} #{shared_path}/system/#{application} stop"
    end

    task :restart, :roles => :app, :except => { :no_release => true } do
      run "RAILS_ENV=#{rails_env} #{shared_path}/system/#{application} upgrade"
    end

    task :cold do
      update
      migrate if uses_database
      start
    end

    task :setup_current_ref do
      sha = ''
      run "cat #{release_path}/REVISION" do |c, s, d|
        sha = d.strip
      end
      set :ref, sha
      puts "Set Ref: #{sha}"
    end

    desc "Automatically called as apart of a standard deploy. Copies the database config from the shared directory over the one provided."
    task :copy_database_configuration do
      production_db_config = "/usr/share/where/shared_config/#{application}.database.yml"
      run "cp -p #{production_db_config} #{release_path}/config/database.yml"
    end

    desc "Automatically called as apart of a standard deploy. Copies the memcache config from the shared directory over the one provided."
    task :copy_memcache_configuration do
      production_mc_config = '/usr/share/where/shared_config/memcache.yml'
      run "cp -p #{production_mc_config} #{release_path}/config/memcache.yml"
    end

    desc "Automatically called as apart of a standard deploy. Create a deploy.json tag in the public directory with information about the release."
    task :tag do
      setup_current_ref
      #TODO: Don't use the user's version of ruby below
      tag = {:app => application, 
             :user => username,
             :deployed_at => Time.now,
             :branch => branch,
             :ruby => RUBY_DESCRIPTION,
             :ref => ref }

      run "echo '#{tag.to_json}' > #{release_path}/public/deploy.json"
    end

    desc "Automaticall called as apart of a standard deploy. Copies the shared resque config to the application if there is a `uses_resque` configuration"
    task :copy_resque_configuration do
      if uses_resque
        resque_config = "/usr/share/where/shared_config/#{application}.resque.yml"
        run "cp -p #{resque_config} #{release_path}/config/resque.yml"
      end
    end

    desc "Automatically called as apart of a standard deploy. Creates the socket tmp/sockets directory"
    task :create_socket_dir, :roles => :app  do
      run "mkdir #{release_path}/tmp/sockets"
    end

    after "deploy:finalize_update", "deploy:create_socket_dir"
    after "deploy:update_code", "deploy:copy_database_configuration"
    after "deploy:update_code", "deploy:copy_memcache_configuration"
    after "deploy:update_code", "deploy:tag"
  end

  namespace :bundler do

    desc "setup Bundler if it is not already setup"
    task :setup, :roles => :app do
      run "echo Installing Bundler; cd #{release_path} && source .rvmrc && ruby -v && gem install bundler"
    end

    desc "Automatically called as apart of a standard deploy."
    task :create_symlink, :roles => :app do
      shared_dir = File.join(shared_path, 'bundle')
      release_dir = File.join(release_path, '.bundle')
      run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
    end

    desc "Automatically called as apart of a standard deploy."
    task :install, :roles => :app do
      run "cd #{release_path} && source .rvmrc && bundle install"

      on_rollback do
        if previous_release
          run "echo previous && cd #{previous_release} && source .rvmrc && bundle install"
        else
          logger.important "no previous release to rollback to, rollback of bundler:install skipped"
        end
      end
    end

    desc "Automatically called as apart of a standard deploy."
    task :bundle_new_release, :roles => :db do
      bundler.create_symlink
      bundler.install
    end
  end

  namespace :whenever_cron do
    task :deploy, :roles => :cron do
      if uses_whenever_cron
        set :whenever_command, "bundle exec whenever"
        set :whenever_environment, env
        set :whenever_roles, :cron
      end
    end
  end

  desc "Automatically called as apart of a standard deploy, unless there is a `no_asset_id` configuration. Runs the rake task asset:id:upload."
  namespace :s3 do
    task :sync_assets, :roles => :db do
      run "cd #{release_path} && source .rvmrc && rake asset:id:upload RAILS_ENV=#{rails_env}" if uses_asset_id
      run "cd #{release_path} && source .rvmrc && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile" if uses_asset_pipeline
    end
  end

  desc "Automatically called as apart of a standard deploy. Runs the hoptoad:deploy rake task to have hoptoad notified."
  namespace :hoptoad do
    task :deploy, :depends => 'deploy:setup_current_ref' do
      run "cd #{release_path} && source .rvmrc && rake hoptoad:deploy TO=#{rails_env} REVISION=#{ref} USER=#{username} RAILS_ENV=#{rails_env}"
    end
  end

  desc "RVM related commands"
  namespace :rvm do

    desc "Setup the project based on the .rvmrc file"
    task :setup, :roles => :app do
      run "echo RVM Installing #{rvm_ruby}; /usr/local/rvm/bin/rvm install #{rvm_ruby}  --with-openssl-dir=/usr/local/rvm/usr"
      run "echo Creating Gemset #{rvm_ruby}@#{application}; rvm use #{rvm_ruby}@#{application} --create"
    end

    task :init, :roles => :app  do
      require 'rvm/capistrano'
      set :rvm_ruby_string, "#{rvm_ruby}@#{application}"
    end

    desc "Set RVM to trust the application's .rvmrc"
    task :trust_rvmrc, :roles => :app  do
      run "/usr/local/rvm/bin/rvm rvmrc trust #{release_path}"
    end

    desc "Create the .rvmrc file for the project"
    task :create_rvmrc, :roles => :app  do
      run "cd #{release_path} && echo '#{rvm_ruby}@#{rvm_gemset}' > .rvmrc"
    end
  end

  desc "Unicorn related tasks"
  namespace :unicorn do
    desc "Creates a symlink to the unicorn management script"
    task :create_symlink, :roles => :app do
      run "ln -s /etc/init.d/unicorn #{shared_path}/system/#{appliction}"
    end
  end

  before "deploy:update_code", "rvm:init"

  before "deploy:setup", "rvm:setup"
  before "deploy:cold", "rvm:init"

  before "bundler:install", "rvm:trust_rvmrc"
  before "bundler:install", "bundler:setup"

  before "hoptoad:deploy", "deploy:setup_current_ref"

  after "deploy:setup", "unicorn:create_symlink"

  after "deploy:update_code", "bundler:bundle_new_release"
  after "deploy:update_code", "deploy:copy_resque_configuration"
  after "deploy:update_code", "rvm:trust_rvmrc"

  after "bundler:bundle_new_release", "whenever_cron:deploy"

  after "deploy:update", "newrelic:notice_deployment" if uses_newrelic

  after "deploy:restart", "s3:sync_assets"
  after "deploy:restart", "deploy:cleanup"
  after "deploy:restart", "hoptoad:deploy" if uses_hoptoad

  if uses_whenever_cron
    require "whenever/capistrano"
  end

end
