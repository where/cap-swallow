Capistrano::Configuration.instance(true).load do

  require 'rubygems'
  require 'json'
  require 'new_relic/recipes'

  namespace :deploy do

    task :start do ; end
    task :stop do  ; end
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
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

    after "deploy:update_code", "deploy:copy_database_configuration"
    after "deploy:update_code", "deploy:copy_memcache_configuration"
    after "deploy:update_code", "deploy:tag"
  end

  namespace :bundler do

    desc "Automatically called as apart of a standard deploy."
    task :create_symlink, :roles => :app do
      shared_dir = File.join(shared_path, 'bundle')
      release_dir = File.join(release_path, '.bundle')
      run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
    end

    desc "Automatically called as apart of a standard deploy."
    task :install, :roles => :app do
      run "cd #{release_path} && sudo bundle install"

      on_rollback do
        if previous_release
          run "echo previous && cd #{previous_release} && sudo bundle install"
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
      run "cd #{release_path} && rake asset:id:upload RAILS_ENV=#{rails_env}"
    end
  end

  desc "Automatically called as apart of a standard deploy. Runs the hoptoad:deploy rake task to have hoptoad notified."
  namespace :hoptoad do
    task :deploy, :depends => 'deploy:setup_current_ref' do
      unless no_hoptoad
        run "cd #{release_path} && rake hoptoad:deploy TO=#{rails_env} REVISION=#{ref} USER=#{username} RAILS_ENV=#{rails_env}"
      end
    end
  end

  before "hoptoad:deploy", "deploy:setup_current_ref"

  after "deploy:update_code", "bundler:bundle_new_release"
  after "deploy:update_code", "deploy:copy_resque_configuration"

  after "bundler:bundle_new_release", "whenever_cron:deploy"

  after "deploy:update", "newrelic:notice_deployment" unless no_newrelic

  after "deploy:restart", "s3:sync_assets" if uses_assets
  after "deploy:restart", "deploy:cleanup"
  after "deploy:restart", "hoptoad:deploy"
  if uses_whenever_cron 
    require "whenever/capistrano"
  end

end
