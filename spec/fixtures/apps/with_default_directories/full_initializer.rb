Bumbleworks.configure! do |c|
  c.root = File.dirname(__FILE__)
  c.storage = {}
end

Bumbleworks.bootstrap!
Bumbleworks.initialize!
Bumbleworks.start_worker!