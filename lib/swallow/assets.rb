Capistrano::Configuration.instance(true).load do

  namespace :assets do
    desc "Runs rake task for asset precompile"
    task :sync, :roles => :app do
      run "cd #{latest_release} && RAILS_ENV=#{env} bundle exec rake assets:precompile" do |chan, stream, data|
        puts "  * [#{chan[:host]}] #{data}" if data.match(/^\s*(Using|Uploading)/)
      end
    end

    desc "Automatically called as apart of a standard deploy, unless there is a `no_asset_id` configuration. Tries to skip asset precomile if its unnecessary."
    task :check, :roles => :app do
      if use_asset_sync
        # check the prev release to see if there are compiled assets there
        previous_assets_exist = true
        run "if [ -e '#{previous_release}/public/assets' ]; then echo 'FOUND'; else echo 'NOT FOUND'; fi" do |chan, stream, data|
          if data.strip != 'FOUND'
            puts "  * Previous Assets Not Found - running asset compilation."
            previous_assets_exist = false
          end
        end

        # Only recompile the assets if they have change.  Lifted (and slightly modified) from:
        # http://stackoverflow.com/questions/9016002/speed-up-assetsprecompile-with-rails-3-1-3-2-capistrano-deployment
        from = source.next_revision(previous_revision)

        # skip sync if we've generated assets before AND there's been no commits to the vendor/assets or app/assets directory
        if deploy_via.to_s != 'remote_cache' || ! previous_assets_exist || capture("cd #{cache_path} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
          sync
        else
          puts "  * Skipping asset pre-compilation because there were no asset changes"
          run "cp -r #{previous_release}/public/assets #{latest_release}/public"
        end

      end
    end
  end

  after "deploy:create_symlink", "assets:check"
end

