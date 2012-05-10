require 'rubygems'
require 'capistrano'

Capistrano::Configuration.instance.load do
  namespace :web do
    desc "Tail the projects's enviroment log."
    task :tail do
      begin
        run "tail -f #{shared_path}/log/#{env}.log"
      rescue Exception => e
        # tail only exits on a user ctrl+c, this will cause an exception to be thrown.
        print "\n"
      end
    end

    desc "Enable the site & take down the maintance page."
    task :enable do
      run "rm /usr/share/where/maintenance"
    end

    desc "Diable the site & put up the maintenance page."
    task :disable do
      run "touch /usr/share/where/maintenance"
    end
  end
end

