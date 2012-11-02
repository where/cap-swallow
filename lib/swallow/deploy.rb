Capistrano::Configuration.instance(true).load do

  require 'rubygems'
  require 'json'
  require 'new_relic/recipes'

  namespace :deploy do

    desc "Sets up a fresh server that does not have any projects on it yet"
    task :init do
    end

    task :start, :roles => :app do
      if use_unicorn
        run "cd #{latest_release} && bundle exec unicorn_rails -c #{current_path}/config/unicorn.rb -E #{rails_env} -D"
      end
    end

    task :stop, :roles => :app do
      if use_unicorn
        run "kill -QUIT `cat #{shared_path}/pids/unicorn.pid`"
      end
    end

    task :restart, :roles => :app, :except => { :no_release => true } do
      run "kill -s USR2 `cat #{shared_path}/pids/unicorn.pid`" if use_unicorn # zero downtime with unicorn
    end

    desc "Used on the first deploy of the project to load the schema into a fresh database"
    task :first do
      update
      if use_database
        load_schema
        seed
      end
      start
    end

    task :cold do
      update
      migrate if use_database
      start
    end

    desc "Loads the database schema into a fresh database"
    task :load_schema, :roles => :db, :only =>  { :primary => true } do
      run "cd #{latest_release} && bundle exec rake RAILS_ENV=#{rails_env} db:schema:load"
    end

    task :migrate, :roles => :db, :only => { :primary => true } do
      migrate_env = fetch(:migrate_env, "")
      migrate_target = fetch(:migrate_target, :latest)

      directory = case migrate_target.to_sym
        when :current then current_path
        when :latest  then latest_release
        else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
        end

      run "cd #{latest_release} && bundle exec rake RAILS_ENV=#{rails_env} #{migrate_env} db:migrate"
      seed if seed_on_migration
    end

    desc "Seeds the database"
    task :seed, :roles => :db, :only => { :primary => true } do
      run "cd #{latest_release} && bundle exec rake RAILS_ENV=#{rails_env} db:seed"
    end

    task :setup_current_ref do
      sha = ''
      run "cat #{latest_release}/REVISION" do |c, s, d|
        sha = d.strip
      end
      set :ref, sha
    end

    desc "Automatically called as apart of a standard deploy. Copies the database config from the shared directory over the one provided."
    task :copy_database_configuration do
      production_db_config = "/usr/share/where/shared_config/#{application}.database.yml"
      run "cp -p #{production_db_config} #{latest_release}/config/database.yml"
    end

    desc "Automatically called as apart of a standard deploy. Copies configs from the shared directory over the one provided."
    task :copy_configs do
      shared_configs = '/usr/share/where/shared_config'
      config_files.each do |filename|
        run "cp -p #{shared_configs}/#{filename} #{latest_release}/config/#{filename}"
      end
    end

    desc "Automatically called as apart of a standard deploy. Create a deploy.json tag in the public directory with information about the release."
    task :tag do
      setup_current_ref

      properties = {}
      run "cat #{latest_release}/config/application.yml 2>/dev/null || true" do |chan, stream, data|
        properties = YAML::load(data) if !data.nil? && data != '' rescue 'error'
      end

      tag = {:app => application, 
             :user => username,
             :deployed_at => Time.now,
             :branch => branch,
             :ruby => capture("ruby -v").strip,
             :ref => ref,
             :properties => properties }

      run "cd #{cache_path} && git log --pretty=oneline | grep 'Merge pull' > #{release_path}/public/qa_info.txt"
      run "echo '#{tag.to_json}' > #{latest_release}/public/deploy.json"
    end

    desc "Remove git files from deploy directory"
    task :cleanup_git, :roles => :app do
      run "rm -rf #{latest_release}/.git*"
    end

    desc "Prevent users from stomping on each other"
    task :prevent_stomp do
      if ENV['HEADLESS'] != 'true' && capture("if [ -e " + deploy_to + "/" + current_dir + "/public/deploy.json ]; then echo 'true'; fi").strip == 'true'
        resp = {}
        run "cat #{deploy_to + "/" + current_dir + "/public/deploy.json"}" do |chan, stream, data|
          host = chan[:host].to_sym
          resp[host] = resp[host].to_s + data
        end

        user = nil
        resp.each_pair do |k, v|
          v.strip!
          existing_user = JSON.parse(v)["user"] rescue nil
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
    end

    desc "Check to see if the application is locked"
    task :check_lock, :roles => :app do
      message = capture("if [ -e #{shared_path}/lock.json ]; then cat #{shared_path}/lock.json; fi").strip
      if !message.empty?
        json = JSON.parse(message)
        puts "Oh Snap! #{json["user"]} locked this at #{json["locked_at"]}"
        puts json["message"] unless json["message"].empty?
        puts "Exiting deploy. Wha wha."
        exit
      end
    end

    desc "Locks the application to prevent any other deploys"
    task :lock, :roles => :app do
      message = ENV['m']
      message = Capistrano::CLI.ui.ask "Lock Message: " if message == nil

      json = { :user => username, :locked_at => Time.now, :message => message }
      run "echo '#{json.to_json}' > #{shared_path}/lock.json"
    end

    desc "Unlocks the application to allow new deploys"
    task :unlock do
      run "if [ -e #{shared_path}/lock.json ]; then rm #{shared_path}/lock.json; fi"
    end

    before "deploy:update_code", "deploy:check_lock"
    before "deploy:update_code", "deploy:prevent_stomp"

    after "deploy:update_code", "deploy:cleanup_git"
    after "deploy:update_code", "deploy:copy_database_configuration"
    after "deploy:update_code", "deploy:copy_configs"
    after "deploy:update_code", "deploy:tag"

    after "deploy", "deploy:cleanup"
  end

  after "deploy:update", "newrelic:notice_deployment" if use_newrelic
end

