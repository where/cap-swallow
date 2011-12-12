Capistrano::Configuration.instance(true).load do

  desc "Automatically called as apart of a standard deploy. Runs the hoptoad:deploy rake task to have hoptoad notified."
  namespace :hoptoad do
    task :notice_deployment, :depends => 'deploy:setup_current_ref' do
      run "cd #{release_path} && source .rvmrc && TO=#{rails_env} REVISION=#{ref} USER=#{username} RAILS_ENV=#{rails_env} bundle exec rake hoptoad:deploy"
    end
  end

  after "deploy:update", "hoptoad:notice_deployment" if use_hoptoad

end


