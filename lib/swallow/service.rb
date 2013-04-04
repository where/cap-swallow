Capistrano::Configuration.instance(true).load do
  namespace :service do

    desc "links services to the init.d directory"
    task :setup, :roles => :app do
      if File.exists? "#{latest_release}/lib/#{application}"
        puts "  * Installing service to init.d"
        run 'cp #{latest_release}/lib/#{application} #{shared_path}/system/#{application}'
        run "sed -i 's/__ENV__/#{rails_env}/g' #{shared_path}/system/#{application}"
        run 'ln -s #{latest_release}/#{application} /etc/init.d/#{application}'
      end
    end

    after "deploy", "service:setup"
  end
end
