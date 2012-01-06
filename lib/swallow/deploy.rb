Capistrano::Configuration.instance(true).load do

  require 'rubygems'
  require 'json'
  require 'new_relic/recipes'

  require 'swallow/rvm'
  require 'swallow/bundler'
  require 'swallow/assets'
  require 'swallow/unicorn'
  require 'swallow/airbrake'
  require 'swallow/whenever_cron'

  namespace :deploy do
    task :start do
      run "RAILS_ENV=#{rails_env} #{shared_path}/system/#{application} start" do

      end
    end

    task :stop do
      run "RAILS_ENV=#{rails_env} #{shared_path}/system/#{application} stop" do

      end
    end

    task :restart, :roles => :app, :except => { :no_release => true } do
      run "RAILS_ENV=#{rails_env} #{shared_path}/system/#{application} restart" do

      end
    end

    task :cold do
      update
      migrate if use_database
      start
    end

    task :migrate, :roles => :db, :only => { :primary => true } do
      migrate_env = fetch(:migrate_env, "")
      migrate_target = fetch(:migrate_target, :latest)

      directory = case migrate_target.to_sym
        when :current then current_path
        when :latest  then latest_release
        else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
        end

      run "cd #{directory} && source .rvmrc && #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate"
    end

    task :setup_current_ref do
      sha = ''
      run "cat #{release_path}/REVISION" do |c, s, d|
        sha = d.strip
      end
      set :ref, sha
    end

    desc "Automatically called as apart of a standard deploy. Copies the database config from the shared directory over the one provided."
    task :copy_database_configuration do
      production_db_config = "/usr/share/where/shared_config/#{application}.database.yml"
      run "cp -p #{production_db_config} #{release_path}/config/database.yml"
    end

    desc "Automatically called as apart of a standard deploy. Copies the paypal config from the shared directory over the one provided."
    task :copy_paypal_configuration do
      production_paypal_config = '/usr/share/where/shared_config/paypal.yml'
      run "cp -p #{production_paypal_config} #{release_path}/config/paypal.yml"
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
             :ruby => capture("cd #{release_path} && source .rvmrc && ruby -v"),
             :rvm => capture("cd #{release_path} && source .rvmrc && rvm-prompt i v p g"),
             :ref => ref }

      run "echo '#{tag.to_json}' > #{release_path}/public/deploy.json"
    end

    desc "Automaticall called as apart of a standard deploy. Copies the shared resque config to the application if there is a `use_resque` configuration"
    task :copy_resque_configuration do
      if use_resque
        resque_config = "/usr/share/where/shared_config/#{application}.resque.yml"
        run "cp -p #{resque_config} #{release_path}/config/resque.yml"
      end
    end

    desc "Automatically called as apart of a standard deploy. Creates the socket tmp/sockets directory"
    task :create_socket_dir, :roles => :app  do
      run "mkdir #{release_path}/tmp/sockets"
    end

    desc "Remove git files from deploy directory"
    task :cleanup_git, :roles => :app do
      run "rm -rf #{release_path}/.git*"
    end

    desc "Prevent users from stomping on each other"
    task :prevent_stomp do
      resp = {}
      run "cat #{deploy_to + "/" + current_dir + "/public/deploy.json"}" do |chan, stream, data|
        host = chan[:host].to_sym
        resp[host] = resp[host].to_s + data
      end

      user = nil
      resp.each_pair do |k, v|
        existing_user = JSON.parse(v)["user"]
        if username != existing_user
          user = existing_user
          break
        end
      end

      if user
        puts "Oh No! #{user} beat you to the punch! Did you ask if you could deploy?"
        prompt_with_default :confirm, 'Nope!', ['Nope!', 'Yep']
        if confirm.upcase != 'YEP'
          puts "Exiting deploy. Please lie to me next time or actually talk to the guy."
          exit
        end
      end
    end

    before "deploy:update_code", "deploy:prevent_stomp"

    after "deploy:finalize_update", "deploy:create_socket_dir"

    after "deploy:update_code", "deploy:cleanup_git"
    after "deploy:update_code", "deploy:copy_database_configuration"
    after "deploy:update_code", "deploy:copy_memcache_configuration"
    after "deploy:update_code", "deploy:copy_paypal_configuration" if use_paypal
    after "deploy:update_code", "deploy:tag"

    after "deploy", "deploy:cleanup"

  end

  after "deploy:update", "newrelic:notice_deployment" if use_newrelic
end
