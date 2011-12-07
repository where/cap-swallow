Capistrano::Configuration.instance(true).load do

  desc "Automatically called as apart of a standard deploy, unless there is a `no_asset_id` configuration. Runs the rake task asset:id:upload."
  namespace :assets do
    task :sync, :roles => :app do
      run "cd #{release_path} && source .rvmrc && rake asset:id:upload RAILS_ENV=#{rails_env}" if uses_asset_id
      run "cd #{release_path} && source .rvmrc && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile" if uses_asset_pipeline
    end
  end

end
