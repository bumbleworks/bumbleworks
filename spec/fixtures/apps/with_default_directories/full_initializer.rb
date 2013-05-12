Bumbleworks.configure! do |c|
  c.root = File.dirname(__FILE__)
  c.storage = {}
  c.autostart_worker = true
end

Bumbleworks.register_participants do
  honey_maker    HoneyParticipant
  molasses_maker MolassesParticipant
end

Bumbleworks.start!