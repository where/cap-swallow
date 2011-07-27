require 'rubygems'
require 'capistrano'

Capistrano::Configuration.instance.load do
  namespace :web do
    task :tag do
      puts "User: #{user}"
    end

    desc "Tail the enviroment log"
    task :tail do
      begin
        run "tail -f #{shared_path}/log/#{env}.log"
      rescue Exception => e
        # tail only exits on a user ctrl+c, this will cause an exception to be thrown.
        print "\n"
      end
    end
  end
end

