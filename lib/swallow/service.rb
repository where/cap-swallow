Capistrano::Configuration.instance(true).load do
  namespace :service do

    desc "links services to the init.d directory"
    task :setup, :roles => :app do
      puts "  * Installing service to init.d"
      # generate service file
      run "cd #{latest_release} && bundle exec rake service:setup /etc/init.d/ #{shared_path} #{current_path} RAILS_ENV=#{rails_env}"
      run "cp #{latest_release}/tmp/system/#{application} #{shared_path}/system/#{application}"
    end

    after "deploy", "service:setup"
  end
end

