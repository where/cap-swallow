unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

# Require the Deploy Hook Files, if they are present
['after_symlink.rb'].each do |script_name|
  script_file_path = "#{Dir.pwd}/hooks/#{script_name}"
  if File.exist?(script_file_path)
    require script_file_path
  end
end

Dir[File.join(File.dirname(__FILE__), 'swallow/*.rb')].sort.each { |lib| require lib }
