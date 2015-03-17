RSpec::Matchers.define :fetch do |method|
  match do |actual|
    actual.send(method) == @receiving_hash.fetch(method.to_s)
  end

  chain :from do |receiving_hash|
    @receiving_hash = receiving_hash
  end
end