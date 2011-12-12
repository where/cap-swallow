Capistrano::Configuration.instance(true).load do
  namespace :bundler do

    desc "setup Bundler if it is not already setup"
    task :setup, :roles => :app do
      begin
        run " cd #{release_path} && source .rvmrc && bundler list"
      rescue Exception => e
        run "echo Installing Bundler; cd #{release_path} && source .rvmrc && gem install bundler"
      end
    end

    desc "Automatically called as apart of a standard deploy."
    task :create_symlink, :roles => :app do
      shared_dir = File.join(shared_path, 'bundle')
      release_dir = File.join(release_path, '.bundle')
      run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
    end

    desc "Automatically called as apart of a standard deploy."
    task :install, :roles => :app do
      run "cd #{release_path} && source .rvmrc && bundle install --path RAILS_ENV=#{rails_env}"

      on_rollback do
        if previous_release
          run "echo previous && cd #{previous_release} && source .rvmrc && bundle install"
        else
          logger.important "no previous release to rollback to, rollback of bundler:install skipped"
        end
      end
    end

    desc "Automatically called as apart of a standard deploy."
    task :bundle_new_release, :roles => :db do
      bundler.create_symlink
      bundler.install
    end
  end
end
