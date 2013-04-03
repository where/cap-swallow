Capistrano::Configuration.instance(true).load do
  namespace :service do

    desc "Install RBENV"
    task :setup, :roles => :app do
      puts "  * Installing service to init.d"
      run 'cp #{latest_release}/lib/campaign_manager #{shared_path}/system/campaign_manager'
      run "sed -i 's/__ENV__/#{rails_env}/g' #{shared_path}/system/campaign_manager"
      run 'ln -s #{latest_release}/campaign_manager /etc/init.d/campaign_manager'
    end

    after "deploy", "service:setup"
  end
end
