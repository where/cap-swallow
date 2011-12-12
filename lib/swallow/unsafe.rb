Capistrano::Configuration.instance.load do
  # Verify intent to deploy
  if verify_intent
    puts 'Cmaaan....really?'
    puts "Deploy #{branch} to #{env}?"
    prompt_with_default :confirm, 'kidding'
    unless confirm == 'yes, really'
      puts 'canceling deploy'
      exit 0
    end
  end
end

