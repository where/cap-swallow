Capistrano::Configuration.instance(true).load do

  desc "Automatically called as apart of a standard deploy, unless there is a `no_asset_id` configuration. Runs the rake task asset:id:upload."
  namespace :assets do
    task :sync, :roles => :app do
      if use_asset_sync
        run "#{source_rvmrc} && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile" do |chan, stream, data|
          puts "  * [#{chan[:host]}] #{data}" if data.match(/^\s*(Using|Uploading)/)
        end
      end

      run "#{source_rvmrc} && RAILS_ENV=#{rails_env} bundle exec rake asset:id:upload" if use_asset_id

    end
  end

  before "deploy:symlink", "assets:sync"
end

