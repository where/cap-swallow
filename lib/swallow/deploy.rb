Capistrano::Configuration.instance(true).load do

  require 'rubygems'
  require 'json'

  namespace :deploy do

    task :start do ; end
    task :stop do  ; end
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
    end

    desc "Automatically called as apart of a standard deploy. Copies the database config from the shared directroy over the one provided."
    task :copy_database_configuration do
      production_db_config = "/usr/share/where/shared_config/#{application}.database.yml"
      run "cp -p #{production_db_config} #{release_path}/config/database.yml"
    end

    desc "Automatically called as apart of a standard deploy. Create a deploy.json tag in the public directory with information about the release."
    task :tag do
      username = gateway.split('@')[0]
      sha = "<unknown>"
      run "cat #{release_path}/REVISION" do |c, s, d|
        puts "Data: #{d}"
        sha = d.strip
      end
      tag = {:user => username,
             :deployed_at => Time.now,
             :branch => branch,
             :ref => sha }

      run "echo '#{tag.to_json}' > #{release_path}/public/deploy.json"
    end

    after "deploy:update_code", "deploy:copy_database_configuration"
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

  desc "Automatically called as apart of a standard deploy. Runs the rake task asset:id:upload."
  namespace :s3 do
    task :sync_assets, :roles => :db do
      run "cd #{release_path} && rake asset:id:upload RAILS_ENV=#{rails_env}"
    end
  end

  desc "Automatically called as apart of a standard deploy. Runs the hoptoad:deploy rake task to have hoptoad notified."
  namespace :hoptoad do
    task :deploy do
      run "cd #{release_path} && rake hoptoad:deploy TO=#{rails_env}"
    end
  end

  after "deploy:update_code", "bundler:bundle_new_release"
  after "deploy:restart", "s3:sync_assets"
  after "deploy:restart", "deploy:cleanup"
  after "deploy:restart", "hoptoad:deploy"
end
