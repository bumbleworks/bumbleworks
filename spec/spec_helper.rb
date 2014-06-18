require 'simplecov'
SimpleCov.start

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require './lib/bumbleworks'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:each) do
    # Yup, we're setting the storage twice - the first time is to
    # ensure that the .reset! isn't trying to access a test double, and
    # the second is to initialize it to a hash for tests.
    Bumbleworks.storage = nil
    Bumbleworks.reset!
    Bumbleworks.storage = {}
  end
end
