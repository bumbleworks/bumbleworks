Bumbleworks.configure! do |c|
  c.root = File.dirname(__FILE__)
  c.storage = {}
end

Bumbleworks.register_participants do
  honey_maker    HoneyParticipant
  molasses_maker MolassesParticipant
end

Bumbleworks.register_tasks
Bumbleworks.load_definitions!
Bumbleworks.start_worker!