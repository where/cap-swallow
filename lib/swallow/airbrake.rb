Capistrano::Configuration.instance(true).load do
  desc "Automatically called as apart of a standard deploy. Runs the airbrake:deploy rake task to have airbrake notified."
  namespace :airbrake do
    task :notice_deployment, :depends => 'deploy:setup_current_ref', :on_error => :continue do
      # TODO: This should get moved from being a boolean var to just being a server role
      capture "cd #{release_path} && TO=#{rails_env} REVISION=#{ref} USER=#{username} RAILS_ENV=#{rails_env} bundle exec rake airbrake:deploy" if use_airbrake
    end
  end

  after "deploy:update", "airbrake:notice_deployment"
end

