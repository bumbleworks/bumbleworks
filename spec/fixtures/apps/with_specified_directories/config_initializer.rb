Bumbleworks.configure! do |c|
  c.root = File.dirname(__FILE__)
  c.definitions_directory = 'specific_directory/definitions'
  c.participants_directory = 'specific_directory/participants'
end
