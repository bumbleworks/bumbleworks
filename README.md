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

If you want to use Redis, set Bumbleworks.storage to a Redis instance.  In a configure block, this looks like:

```ruby
Bumbleworks.configure do |c|
  c.storage = Redis.new(:host => '127.0.0.1', :db => 0, :thread_safe => true)
  # ...
end
```

#### Sequel

If you want to use Sequel, set Bumbleworks.storage to a Sequel database connection.  You can use Sequel.connect for this.  In a configure block, this looks like:

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

### The Task Queue

Bumbleworks, by default, uses...

### Starting Work

Without running a "worker," Bumbleworks won't do anything behind the scenes - no workitems will proceed through their workflow, no schedules will be checked, etc.  To run a worker, use the following rake task:

```
rake bumbleworks:start_worker
```

You can run as many workers as you want in parallel, and as long as they're accessing the same storage, no concurrency issues should arise.
