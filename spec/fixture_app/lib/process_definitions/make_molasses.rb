Bumbleworks.define_process 'make_molasses' do
  concurrence do
    dave :ref => 'maker'
    sam :ref => 'taster'
  end
end
