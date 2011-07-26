Dir[File.join(File.dirname(__FILE__), 'swallow/*.rb')].sort.each { |lib| require lib }

