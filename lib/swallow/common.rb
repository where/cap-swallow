class Hash
  def recursive_merge(h)
    self.merge!(h) {|key, _old, _new| if _old.class == Hash then _old.recursive_merge(_new) else _new end  } 
  end
end

Capistrano::Configuration.instance.load do
  def cache_path
    "#{shared_path}/cached-copy"
  end

  def prompt_with_default(var, default, options=[])
    set(var) do
      opts = options.length > 0 ? "(#{options.join(', ')})" : ''
      Capistrano::CLI.ui.ask "#{var} #{opts} [#{default}] : "
    end
    set var, default if eval("#{var.to_s}.empty?")
  end

  def rvm_run(command)
    run "cd #{release_path} && source .rvmrc && #{command}"
  end

  _cset(:application_config) { "#{Dir.pwd}/config/deploy.yml" }

  # Load settings from yaml
  config = YAML.load_file( File.join(File.dirname(__FILE__), '../../config/deploy.yml'))

  if File.exists?(application_config)
    puts "Loading application config: #{application_config}"
    config.recursive_merge(YAML.load_file(application_config))
  else
    puts "Using defaults only"
  end

  settings = {}

  # Extract available envs from yaml, excluding default
  available_envs = config.keys.reject{ |k| k == 'default'}

  # Unless used passed env, prompt them to enter it
  set :env, ENV['e']
  prompt_with_default(:env, 'staging', available_envs) if env == nil

  # Set settings for the env
  settings = config[env]

  # No settings, halt
  if settings == nil
    puts "Invalid ENV #{env}! Use one of #{available_envs.join(', ')}!"
    exit 1
  end

  # branch / tag override
  branch = ENV['r']
  branch = settings['default_branch'] if branch == nil
  settings.merge!({'branch' => branch})

  if ENV['GATEWAY'] == 'false'
      settings['username'] = ENV['USER']
  else
    # Set gateway
    settings.merge!('gateway' => "#{ENV['USER']}@#{settings['gateway_server']}")

    # Set username (the actual username that is logged into the gateway, not the user on the box)
    settings['username'] = settings['gateway'].split('@')[0] rescue ''
  end

  # Ensure Symbol Values
  ['scm', 'deploy_via'].each do |key|
    settings.merge!(key.to_s => settings[key.to_s].to_sym)
  end

  # Set all settings as cap configs
  settings.each do |s|
    set s[0].to_sym, s[1]
  end

  # Generate all of the web and app server names
  server_names = servers.map do |n| 
    "#{n}.#{env_name}"
  end

  send(:role, *[:web,  *server_names])
  send(:role, *[:app,  *server_names])

  # migrations will run if use_database is enabled
  role :db,   "#{db_server}.#{env_name}", :no_release => !use_database, :primary => true

  # where cron jobs will be added
  role :cron, "#{cron_server}.#{env_name}", :primary => true

  unless daemon_server.nil? || daemon_server.strip == ''
    role :daemon, "#{daemon_server}.#{env_name}", :primary => true
  end
end

