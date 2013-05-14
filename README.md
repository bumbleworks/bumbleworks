# Bumbleworks

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

### The Process Storage

Bumbleworks uses a dedicated key-value storage for process information; this is where all process instance state is stored.  We consider it a best practice to keep this storage in a separate place from your business information; see Process vs. Business Information for more discussion.

Before you can load process definitions, register participants, and spin up workers in Bumbleworks, you need to configure Bumbleworks's process storage.  Right now, Bumbleworks supports two storage methods - [Redis](http://redis.io/) and [Sequel](http://sequel.rubyforge.org/) (an ORM that itself supports MySQL, Postgres, etc.).

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

### Process Definition Loading

Bumbleworks uses [ruote](http://github.com/jmettraux/ruote), which allows process definitions to be written using a [Ruby DSL](http://ruote.rubyforge.org/definitions.html#ruby).  By default, your process definitions will be loaded from the `lib/process_definitions` directory at `Bumbleworks.root` (see Determining the Root Directory for more info).  This directory can have as many subdirectories as you want, and Bumbleworks will load everything recursively; note, however, that the directory hierarchy doesn't mean anything to Bumbleworks, and is only for your own organization.  The directory is configurable by setting Bumbleworks.definitions_directory:

```ruby
Bumbleworks.configure do |c|
  c.definitions_directory = '/absolute/path/to/your/process/definitions/directory'
  # ...
end
```

Note that if you override the default path, you can either specify an absolute path or a relative path - just use a leading slash if you want it to be interpreted as absolute.

## Participant Class Registration

Registering participants with Bumbleworks is done using Bumbleworks.register_participants, which takes a block, and follows [Ruote's #register syntax](http://ruote.rubyforge.org/participants.html#registering).  For example:

```ruby
Bumbleworks.register_participants do
  update_status StatusChangerParticipant
  acquire_lock LockerParticipant, 'action' => 'acquire'
  release_lock LockerParticipant, 'action' => 'release'
  notify_applicant ApplicantNotifierParticipant
end
```

By default, Bumbleworks will register a "catchall" participant at the end of your participant list, which will catch any workitems not picked up by a participant higher in the list.  Those workitems then fall into ruote's StorageParticipant, from where Bumbleworks will assemble its task queue.

If your app has a `participants` or `app/participants` directory at the root (see Determining the Root Directory), Bumbleworks will require all files in that directory by default before running the `register_participants` block.  You can customize this directory by setting Bumbleworks.participants_directory:

```ruby
Bumbleworks.configure do |c|
  c.participants_directory = '/absolute/path/to/your/participant/class/files'
  # ...
end
```

### Determining the Root Directory

By default, Bumbleworks will attempt in several ways to find your root directory.  In the most common cases (Rails, Sinatra, running via Rake), it usually won't have trouble guessing the directory.

## Usage

### Starting Work

Without running a "worker," Bumbleworks won't do anything behind the scenes - no workitems will proceed through their workflow, no schedules will be checked, etc.  To run a worker, you can either set the `autostart_worker` option in configuration, before starting Bumbleworks:

```ruby
Bumbleworks.configure do |c|
  # ...
  # NOTE: NOT RECOMMENDED IN PRODUCTION!
  c.autostart_worker = true
end

Bumbleworks.start! # this will now start a worker automatically
```

... but, while this is handy in development and testing, it's not a good practice to follow in production.  In an actual production environment, you will likely have multiple workers running in their own threads, or even on separate servers.  So the **preferred way** is to do the following (most likely in a Rake task that has your environment loaded):

```ruby
Bumbleworks.start_worker!
```

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