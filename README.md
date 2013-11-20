# Bumbleworks

**IMPORTANT**: Ruote (a dependency of Bumbleworks) currently has a bug in its dependency graph.  Until this is fixed (and we'll update this readme when it is), make sure you add this to your gemfile:

```ruby
gem 'rufus-scheduler', '~> 2.0'
```

**NOTE**: This product is still pre-release, and implementation is *not* in sync with documentation yet - hence the pre-release version.  We'll follow [the Semantic Versioning Specification (Semver)](http://semver.org/), so you can assume anything at 0.x.x still has an unstable API.  But we *are* actively developing this.

Bumbleworks is a gem that adds a workflow engine (via [ruote](http://github.com/jmettraux/ruote)) to your Ruby application, and adds tools for task authorization and locking.  It also establishes conventions for easily loading process definitions and registering participant classes based on configurable file locations.

Bumbleworks itself does not include a presentation layer; however, it is easily integrated into your application, and we're working on concocting several examples of how to integrate into different frameworks.

## Installation

If you're using bundler, just add it to your Gemfile:

```ruby
gem 'bumbleworks'
```

and then execute:

    $ bundle

Or you can install it yourself using

    $ gem install bumbleworks

## Configuration

#### Example Initializer File

```ruby
Bumbleworks.configure do |c|
  c.storage = Redis.new # requires bumbleworks-redis gem
  # Or, for dev/test, if you don't have Redis set up yet:
  # c.storage = {}
end

# this next block is optional - it's only needed
# if you want to load custom participants
Bumbleworks.register_participants do
  # foo FooParticipant
  # bar BarParticipant
  # ...
end

# Load all process definitions in lib/process_definitions
Bumbleworks.load_definitions!

# Start a worker in the background
Bumbleworks.start_worker!
```

### The Process Storage

Bumbleworks uses a dedicated key-value storage for process information; this is where all process instance state is stored.  We consider it a best practice to keep this storage in a separate place from your business information; see Process vs. Business Information for more discussion.

Before you can load process definitions, register participants, and spin up workers in Bumbleworks, you need to configure Bumbleworks's process storage.  Right now, Bumbleworks supports three storage methods - [Redis](http://redis.io/), [Sequel](http://sequel.rubyforge.org/) (an ORM that itself supports MySQL, Postgres, etc.), and a simple Hash (only for development and testing, since it won't persist )

#### Redis

If you want to use Redis:

1. Add the gem to your Gemfile:

  ```ruby
  gem 'bumbleworks-redis'
  ```

2. Set Bumbleworks.storage to a Redis instance.  In a configure block, this looks like:

  ```ruby
  Bumbleworks.configure do |c|
      c.storage = Redis.new(:host => '127.0.0.1', :db => 0, :thread_safe => true)
      # ...
  end
  ```

#### Sequel

If you want to use Sequel:

1. Add the gem to your Gemfile:

  ```ruby
  gem 'bumbleworks-sequel'
  ```

2. Set Bumbleworks.storage to a Sequel database connection.  You can use Sequel.connect for this.  In a configure block, this looks like:

  ```ruby
  Bumbleworks.configure do |c|
      c.storage = Sequel.connect('postgres://user:password@host:port/database_name')
      # ...
  end
  ```

### Process Definitions Directory

Bumbleworks uses [ruote](http://github.com/jmettraux/ruote), which allows process definitions to be written using a [Ruby DSL](http://ruote.rubyforge.org/definitions.html#ruby).

By default, your process definitions will be loaded from the `lib/process_definitions` directory at `Bumbleworks.root` (see Determining the Root Directory for more info).  This directory can have as many subdirectories as you want, and Bumbleworks will load everything recursively; note, however, that the directory hierarchy doesn't mean anything to Bumbleworks, and is only for your own organization.  The directory is configurable by setting Bumbleworks.definitions_directory:

```ruby
Bumbleworks.configure do |c|
  c.definitions_directory = '/absolute/path/to/your/process/definitions/directory'
  # ...
end
```

Note that if you override the default path, you can either specify an absolute path or a relative path - just use a leading slash if you want it to be interpreted as absolute.  Relative paths will be relative to `Bumbleworks.root`.

### Participant Class Directory

If your app has a `participants` or `app/participants` directory at the root (see Determining the Root Directory), Bumbleworks will require all files in that directory by default before running your `register_participants` block (see below).  You can customize this directory by setting Bumbleworks.participants_directory:

```ruby
Bumbleworks.configure do |c|
  c.participants_directory = '/absolute/path/to/your/participant/class/files'
  # ...
end
```

### Determining the Root Directory

By default, Bumbleworks will attempt in several ways to find your root directory.  In the most common cases (Rails, Sinatra, or Rory), it usually won't have trouble guessing the directory.

If you're not using Rails, Sinatra, or Rory, Bumbleworks will complain when you call `bootstrap!` or `update!`, **unless** both your definitions directory and your participants directory (see above) are specified as absolute paths.

## Usage

### Loading Definitions and Participants

#### Process Definitions

Process definitions are just ruby files with blocks following Ruote's [Ruby DSL syntax](http://ruote.rubyforge.org/definitions.html#ruby).  The only difference is that instead of `Ruote.define`, the method to call is `Bumbleworks.define_process`.  No arguments are necessary - the name will be taken from the base name of the ruby file (e.g. 'foo.rb' defines a process named 'foo').  All process definition files should be in your app's `definitions_directory` (see above); they can be in subdirectories for your own organization, but all filenames must be unique within the `definition_directory`'s tree.

To actually load your process definitions from the directory:

```ruby
Bumbleworks.load_definitions!
```

Keep in mind that any changed process definitions will overwrite previously loaded ones - in other words, after running this command successfully, all process definitions loaded into Bumbleworks will be in sync with the files in your definitions directory.

Process definitions will be named (and `launch`able) using the name of the file itself.  Therefore, Bumbleworks will throw an exception if any files in your definitions directory (and subdirectories) have the same name.

#### Participants

Registering participants with Bumbleworks is done using `Bumbleworks.register_participants`, which takes a block, and follows [Ruote's #register syntax](http://ruote.rubyforge.org/participants.html#registering).  For example:

```ruby
Bumbleworks.register_participants do
  update_status StatusChangerParticipant
  acquire_lock LockerParticipant, 'action' => 'acquire'
  release_lock LockerParticipant, 'action' => 'release'
  notify_applicant ApplicantNotifierParticipant
end
```

Unless you add it yourself, Bumbleworks will register a "catchall" participant at the end of your participant list, which will catch any workitems not picked up by a participant higher in the list.  Those workitems then fall into ruote's StorageParticipant, from where Bumbleworks will assemble its task queue.

### Starting Work

Without running a "worker," Bumbleworks won't do anything behind the scenes - no workitems will proceed through their workflow, no schedules will be checked, etc.  Running a worker is done using the following command:

```ruby
Bumbleworks.start_worker!
```

You can add this to the end of your initializer, but, while this is handy in development and testing, it's not a good practice to follow in production.  In an actual production environment, you will likely have multiple workers running in their own threads, or even on separate servers.  So the **preferred way** is to call the `Bumbleworks.start_worker!` method outside of the initializer, most likely in a Rake task that has your environment loaded.

> Strictly speaking, the entire environment doesn't need to be loaded; only Bumbleworks.storage needs to be set before starting a worker.  However, it's best practice to configure Bumbleworks in one place, to ensure you don't get your storage configurations out of sync.

You can run as many workers as you want in parallel, and as long as they're accessing the same storage, no concurrency issues should arise.

### The Task Queue

When a worker encounters an expression that doesn't match a subprocess or a participant, it gets dropped into the storage and waits to be picked up and dealt with.  Using the Bumbleworks::Task class, Bumbleworks makes available any of these items that have a param called "task."  Let's use the following expressions as an example:

```ruby
concurrence do
  trombonist :task => 'have_a_little_too_much_fun'
  admin :task => 'clean_up_after_trombone_quintet'
  rooster :do => 'something_nice'
end
```

If you call Bumbleworks::Task.all, both of the first two will be returned as Task instances - the third one will be ignored.  You can also do:

```ruby
Bumbleworks::Task.for_role('trombonist') # returns first task
Bumbleworks::Task.for_role('admin') # returns second task
Bumbleworks::Task.for_roles(['trombonist', 'admin']) # returns both tasks
```

Call Bumbleworks::Task#complete to finish a task and proceed to the next expression.

See the Bumbleworks::Task class for more details.

## Rake Tasks

If you...

```ruby
require 'bumbleworks/rake_tasks'
```

... in your Rakefile, Bumbleworks will give you a couple of rake tasks.  Both of these rake tasks expect an `environment` Rake task to be specified that loads your application's environment (Rails, for example, gives you this automatically).

The tasks are:

1. `rake bumbleworks:start_worker`

  This task starts a Bumbleworks worker, and does not return.  It will expect Bumbleworks to be required and for Bumbleworks' storage to be configured.

2. `rake bumbleworks:reload_definitions`

  All process definitions will be reloaded from the configured `definitions_directory`.

## Contributing

1. Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
1. Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
1. Fork the project.
1. Start a feature/bugfix branch.
1. Commit and push until you are happy with your contribution.
1. Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
1. Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
