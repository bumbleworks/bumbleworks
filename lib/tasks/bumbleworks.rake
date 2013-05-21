namespace :bumbleworks do
  desc 'Start a Bumbleworks worker'
  task :start_worker => :environment do
    Bumbleworks.start_worker!
  end

  desc 'Reload all process definitions from directory'
  task :reload_definitions => :environment do
    Bumbleworks.load_definitions!
  end
end