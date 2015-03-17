RSpec::Matchers.define :delegate do |method|
  match do |actual|
    actual.send(method) == @receiving_object.send(method)
  end

  chain :to do |receiving_object|
    @receiving_object = receiving_object
  end
end