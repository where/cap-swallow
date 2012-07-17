Capistrano::Configuration.instance(true).load do
  def run_remote_rake(rake_cmd)
    rake_args = ENV['RAKE_ARGS'].to_s.split(',')

    cmd = "cd #{fetch(:latest_release)} && bundle exec #{fetch(:rake, "rake")} RAILS_ENV=#{fetch(:rails_env, "production")} #{rake_cmd}"
    cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
    run cmd
    set :rakefile, nil if exists?(:rakefile)
  end

  namespace :deploy do
    desc "Restart Resque Workers"
    task :restart_workers, :roles => :worker do
      run_remote_rake "resque:restart_workers"
    end
  end
  
  after "deploy", "deploy:restart_workers"
end

