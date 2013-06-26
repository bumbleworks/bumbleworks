Bumbleworks.define_process 'make_molasses' do
  concurrence do
    dave :task => 'make_some_molasses'
    sam :task => 'taste_that_molasses'
  end
end
