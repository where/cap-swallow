Capistrano::Configuration.instance.load do
  namespace :web do
    desc "Tail the enviroment log"
    task :tail do
      begin
        run "tail -f #{shared_path}/log/#{env}.log"
      rescue
        "Done"
      end
    end
  end
end

