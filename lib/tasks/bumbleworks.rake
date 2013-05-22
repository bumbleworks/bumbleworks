namespace :bumbleworks do
  desc 'Start a Bumbleworks worker'
  task :start_worker => :environment do
    puts "Starting Bumbleworks worker..." if verbose == true
    Bumbleworks.start_worker!(:join => true, :verbose => verbose)
  end

  desc 'Reload all process definitions from directory'
  task :reload_definitions => :environment do
    puts "Reloading all Bumbleworks process definitions..." if verbose == true
    Bumbleworks.load_definitions!(:verbose => verbose)
  end

  desc 'Launch a given Bumbleworks process'
  task :launch, [:process] => :environment do |task, args|
    process = args[:process]
    raise ArgumentError, "Process name required" unless process
    puts "Launching process '#{process}'..." if verbose == true
    wfid = Bumbleworks.launch!(process)
    puts "WFID: #{wfid}" if verbose == true
  end
end