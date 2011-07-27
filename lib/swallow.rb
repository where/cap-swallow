unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

Dir[File.join(File.dirname(__FILE__), 'swallow/*.rb')].sort.each { |lib| require lib }
