# Quick Start for Rails

1. Install [Rails](http://rubyonrails.org) and [redis](http://redis.io).

1. Create a new Rails application.

  ```
  $ rails new bumbleworks_quickstart_rails
  $ cd bumbleworks_quickstart_rails
  ```

1. Add Bumbleworks and the Redis storage adapter to your Gemfile.

  ```ruby
  gem 'bumbleworks'
  gem 'bumbleworks-redis'
  ```

1. Install the gems in your Gemfile.
  ```
  $ bundle install
  ```

1. Create an initializer at `config/initializers/bumbleworks.rb`:

  ```ruby
    Bumbleworks.configure do |c|
        c.storage = Redis.new
    end

    Bumbleworks.initialize!
  ```

1. Add your first process definition at `lib/bumbleworks/process_definitions/` (or `lib/bumbleworks/processes`):

  ```ruby
  Bumbleworks.define_process do
      # write your process definition here
  end
  ```

  Process definitions follow the same syntax as [ruote](http://ruote.rubyforge.org/definitions.html), but are defined using `Bumbleworks.define_process` instead of `Ruote.define`.

1. (*optional*) Put any [custom participants](http://ruote.rubyforge.org/implementing_participants.html) in `lib/bumbleworks/participants`.

1. (*optional*) Create a participant registration file at `lib/bumbleworks/participants.rb` with the following:

  ```ruby
    Bumbleworks.register_participants do
        # foo FooParticipant
        # bar BarParticipant
        # ... any other custom participants you created
    end
  ```

1. Run the `bumbleworks:bootstrap` rake task to load your process definitions and participant list
into your process storage (the Redis database).

1. You can now launch processes using `Bumbleworks.launch!('process_definition_name')`.  `#launch!` takes a hash as an optional second argument - anything set here will become workitem fields.  A special key, `:entity`, can be used to specify a persistent business entity for the process, which will be retrievable from process tasks (using `Task#entity`).

1. Any expressions of the form `[role] :task => [task_name]` will be turned into tasks retrievable at `Bumbleworks::Task.all`; you can get tasks specific to a role or roles using `Bumbleworks::Task.for_roles([role1, role2, ...])`.
