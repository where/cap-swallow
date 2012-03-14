Capistrano::Configuration.instance(true).load do

  desc "Automatically called as apart of a standard deploy, unless there is a `no_asset_id` configuration. Runs the rake task asset:id:upload."
  namespace :assets do
    task :sync, :roles => :app do
      if use_asset_sync
        # Only recompile the assets if they have change.  Lifted (and slightly modified) from:
        # http://stackoverflow.com/questions/9016002/speed-up-assetsprecompile-with-rails-3-1-3-2-capistrano-deployment
        from = source.next_revision(current_revision)

        # deploy_via remote_cache is the only method that currently supports detecting if the assets
        # have already been precompiled and using that as instead of recompiling.

        previous_assets_exist = true
        run "if [ -e '#{previous_release}/public/assets' ]; then echo 'FOUND'; else echo 'NOT FOUND'; fi" do |chan, stream, data|
          if data.strip != 'FOUND'
            puts "!!! Previous Assets Not Found - cannot skip asset compilation.  Did you cancel out of a deploy before it finished?"
            previous_assets_exist = false
          end
        end

        if deploy_via.to_s != 'remote_cache' || ! previous_assets_exist ||  
           capture("cd #{cache_path} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0 
          run "#{source_rvmrc} && RAILS_ENV=#{rails_env} bundle exec rake assets:precompile" do |chan, stream, data|
            puts "  * [#{chan[:host]}] #{data}" if data.match(/^\s*(Using|Uploading)/)
          end
        else
          puts "  * Skipping asset pre-compilation because there were no asset changes"
          run "cp -r #{previous_release}/public/assets #{release_path}/public"
        end

      end

      run "#{source_rvmrc} && RAILS_ENV=#{rails_env} bundle exec rake asset:id:upload" if use_asset_id

    end
  end

  before "deploy:symlink", "assets:sync"
end

