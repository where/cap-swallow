Capistrano::Configuration.instance(true).load do
  namespace :service do

    desc "links services to the init.d directory"
    task :setup, :roles => :app do
      if File.exists? "#{latest_release}/lib/#{application}.erb"
        puts "  * Installing service to init.d"
        service_file = ERB.new(File.new(Rails.root.join( 'lib', "#{latest_release}/lib/#{application}.erb")).read, nil, "%").result()
        File.new("#{shared_path}/system/#{application}", "w") { |f| f.write(service_file) }
        File.symlink("#{shared_path}/system/#{application}", "/etc/init.d/#{application}")
      end
    end

    after "deploy", "service:setup"
  end
end
