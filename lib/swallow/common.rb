unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

Capistrano::Configuration.instance.load do
  # Load settings from yaml
  config = YAML.load_file( File.join(File.dirname(__FILE__), '../../config/deploy-settings.yml'))

  settings = {}

  def prompt_with_default(var, default, options=[])
    set(var) do
      opts = options.length > 0 ? "(#{options.join(', ')})" : ''
      Capistrano::CLI.ui.ask "#{var} #{opts} [#{default}] : "
    end
    set var, default if eval("#{var.to_s}.empty?")
  end

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

  # TODO: Move this into the deploy, put soemthing else like this here.
  puts "Deploying #{settings['branch']} to #{env}"

  # yes we could do ruby coolness, but this seems safer
  [:application, :repository, :gateway,
    :deploy_to, :deploy_via, :user,
    :env_name, :rails_env, :default_env,
    :branch, :copy_exclude, :use_sudo, :scm].each do |key| 
    set key, settings[key.to_s] # Settings uses string keys 
  end

  # SERVER ROLES
  role :web, "app01.#{env_name}", "app02.#{env_name}"
  role :app,  "app01.#{env_name}", "app02.#{env_name}"
  role :db,  "app01.#{env_name}", :primary => true
end
