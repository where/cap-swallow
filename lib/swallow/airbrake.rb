Capistrano::Configuration.instance(true).load do
  desc "Automatically called as apart of a standard deploy. Runs the airbrake:deploy rake task to have hoptoad notified."
  namespace :airbrake do
    task :notice_deployment, :depends => 'deploy:setup_current_ref' do
      run "#{source_rvmrc} && TO=#{rails_env} REVISION=#{ref} USER=#{username} RAILS_ENV=#{rails_env} bundle exec rake airbrake:deploy" if use_airbrake
      run "#{source_rvmrc} && TO=#{rails_env} REVISION=#{ref} USER=#{username} RAILS_ENV=#{rails_env} bundle exec rake hoptoad:deploy" if use_hoptoad
    end
  end

  before "deploy:symlink", "airbrake:notice_deployment"
end

