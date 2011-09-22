class Hash
  def recursive_merge(h)
    self.merge!(h) {|key, _old, _new| if _old.class == Hash then _old.recursive_merge(_new) else _new end  } 
  end
end

Capistrano::Configuration.instance.load do
  def prompt_with_default(var, default, options=[])
    set(var) do
      opts = options.length > 0 ? "(#{options.join(', ')})" : ''
      Capistrano::CLI.ui.ask "#{var} #{opts} [#{default}] : "
    end
    set var, default if eval("#{var.to_s}.empty?")
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

  # Ensure Symbol Values
  ['scm', 'deploy_via'].each do |key|
    settings.merge!(key.to_s => settings[key.to_s].to_sym)
  end

  # branch / tag override
  branch = ENV['r']
  branch = settings['default_branch'] if branch == nil
  settings.merge!({'branch' => branch})

  # Set gateway
  settings.merge!('gateway' => "#{ENV['USER']}@#{settings['gateway_server']}")

  # TODO: Make this optional/in a common file for unsafe actions
  # Verify intent to deploy
  if settings['verify_intent']
    puts 'Cmaaan....really?'
    puts "Deploy #{settings["branch"]} to #{env}?"
    prompt_with_default :confirm, 'kidding'
    unless confirm == 'yes, really'
      puts 'canceling deploy'
      exit 0
    end
  end

  settings['username'] = settings['gateway'].split('@')[0] rescue ''

  # yes we could do ruby coolness, but this seems safer
  [:application, :repository, :gateway,
    :deploy_to, :deploy_via, :user,
    :env_name, :rails_env, :default_env,
    :username, :uses_resque, :uses_whenever_cron,
    :branch, :copy_exclude, :use_sudo, :scm,
    :no_asset_id, :no_hoptoad, :no_newrelic,
    :number_of_app_servers].each do |key| 
    set key, settings[key.to_s] # Settings uses string keys 
  end

  # SERVER ROLES
  server_names = (1..(number_of_app_servers||2)).to_a.collect do |n| 
    "app#{('%02d' % n)}.#{env_name}"
  end

  send(:role, *[:web,  *server_names])
  send(:role, *[:app,  *server_names])
  role :db,   "app01.#{env_name}", :primary => true     # This is where Rails migrations will run
  role :cron, "app01.#{env_name}", :primary => true     # This is where cron jobs will be added
end
