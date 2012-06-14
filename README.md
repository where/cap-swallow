# Swallow

# New Server Setup
1. Have systems create a new vanilla web image.
2. Run `$ cap deploy:init` to initialize the server. This will:
    * Install RBEnv (`rbenv:init`)
    
# New Project Setup
1. Copy the default `Capfile` from the Swallow project to the project's root.
2. Copy the default `config/deploy.yml` to the project.
3. Edit `deploy.yml` to match the project's needs. See the config section to get an understanding for what is needed and what is not.
4. If the project will use unicorn, follow the setting up unicorn instructions.
5. Run `$ cap deploy:setup` and select the targeted environment. This will:
    * Create the project's main directory structure 
    * Install the project's specified ruby version (`rbenv:setup_ruby`)
    * Create the shared unicorn  (`unicorn:setup_sockets_dir`)
6. Run `$ cap deploy:cold`. This will:
    * Install the project's version of ruby if it's not already installed (`rbenv:setup_ruby`)
    * Pull down the latest code from GitHub
    * Properly link the standard shared directories to the project (i.e. /log, /tmp/pids)
    * Link the unicron sockets directory (`unicorn:create_socket_dir`)
    * Install bundler if its not already installed (`bundler:setup`)
    * Install required gems (`bundler:install`)
    * Copy over the database and any other config files (`deploy:copy_database_configuration` and `deploy:copy_configs`)
    * Create the project's deploy tag (`deploy:tag`)
    * Sync any assets that need to be sent to the CDN (`assets:sync`)
    * Run the airbrake/hoptoad & New Relic deploy notifications (`airbrake:notice_deployment` and `newrelic:notice_deployment`)
    * Run the database migrations (`deploy:migrate`)
7. Run `$ cap deploy:migrations`. This will:
    * Create (``)
    * Create (``)
    * Create (``)
    * Create (``)
 