# Bumbleworks

## The Zen Clock

Imagine you just got your MBA.

You've got a friend in Morocco who's inexplicably excited about a new product she's invented - the Zen Clock - and is anxious to get it out of her head and onto the nightstands and wicker end tables of millions of customers.  She's never sold anything bought or processed, or bought anything sold or processed, or processed anything sold, bought, or processed, and neither have you.  Honestly, this is *at best* a risky business move, and at worst your first step towards total emotional and financial collapse, but let's put rationality aside for now.

We've already designed the clock, sourced its parts, built a prototype, and subjected it to a rigorous 2-day testing period (from which the only lingering issue is the Clock's dismal failure at estimating the current time).  We've settled on four models, each one slightly larger and slightly more yellow than the last.

Now let's build a Zen Clock factory.

## The Plan

The first thing you'll need (aside from a deep breath and some Xanax) is a Plan.  The plan will be the blueprint for how we'll set up the assembly line, and what work will actually happen on that line.

Here's a first draft:

#### The Zen Clock Assembly Line Plan

  1. Receive an order
  2. Place box of parts on conveyor belt
  3. Make clock
  4. Ship clock to excited customers
  5. Receive angry calls
  6. Go into hiding

Looks great!  But you know what?  We're agile, and extreme, and cross-country-functional, and 2.0, so let's just go ahead and start building our factory - we'll develop it iteratively.

## Our First Bumbleworks App

First, let's start a new [Rails](http://rubyonrails.org) app.  You'll need, um, the Rails gem, and Ruby, and a computer, and.. you know what?  We're just going to assume you've got the Rails gem installed.  If not, [there are places you can go](http://rubyonrails.org/download) to find out how.

> Look, I know you just wrote your own web framework for Ruby, and it uses DCI, and Octagonal Composition, and the Observitating De-executor Pattern from Lowland & Michael's PTTD 7th Edition, and your eyelashes literally pucker in disgust when someone suggests you use "off the shelf software."  But we're still going to use Rails for our tutorial, because we're too good for elitists like you.

#### Rails

Okay, now do this in a shell:

    $ rails new zen_clock
    $ cd zen_clock

A bunch of crazy words will show up on your screen, probably in green text against a black background, unless you're lame.  Congratulations!  You know how to copy and paste.

#### Adding the Bumbleworks Gem
The first thing we need to do is corrupt our fresh Rails install with the Bumbleworks gem.  Edit `Gemfile` and add:

```ruby
gem 'bumbleworks'
```

And then, back in your shell:

    $ bundle install

Once again, your screen will fill up with nonsense words, making you appear esoterically smart.  Men and/or women (choose which one(s) you want to impress) love that.

#### The Bumbleworks Data Store

Bumbleworks needs its own data store, used only for process state.  We'll explore why this is important later, but for now, just accept that Bumbleworks had neglectful parents and is bad at sharing.

Out of the box, Bumbleworks supports three storage types - [Redis](http://redis.io), [Sequel](http://sequel.rubyforge.org), and a simple Ruby Hash.  We're going to use the latter for now, since it requires no setup.  You would never use the Hash storage type for production - it's in-memory and in-process, so it won't survive a restart and you can't run multiple workers.  But for testing, it's ideal.

### Writing a Process Definition


In Bumbleworks, our plan above (for now, we'll ignore steps 5 and 6, mostly because we're in denial) might look something like this:

```ruby
Bumbleworks.define_process :name => 'build_zen_clock' do
  make
  ship
end
```

Hang on, where are steps 1 and 2 ("Receive an order" and "Place box of parts on conveyor belt")?  Good question!  You're really paying attention, here.  Has anyone ever told you you're very detail-oriented?

## Starting the Process

Let's take a step back, and think about the life cycle of a Zen Clock.  To simplify things (and because we're admittedly not that business-savvy), we're not going to concern ourselves with inventory or volume or anything like that.  We're selling one clock at a time.

### How A Zen Clock is Born

Our bleary-eyed customer (we'll call him Roanoke, after the similarly ill-fated American colony), having stayed awake well past the 11pm news, sees the Zen Clock on an infomercial, and in a fit of bad judgement decides to order one.  He calls the toll free number, gives his information, and his fate is sealed.

A Zen Clock comes into existence the moment someone places an order, even before it is tangible in the physical realm.  How very like a Zen Clock.

```ruby
class ZenClock
  def initialize(customer)
    @customer = customer
  end
end

# When our customer places an order:
zen_clock = ZenClock.new(:roanoke)
```

We've created a ZenClock class, and given it an initializer method.  The initializer takes, as its single argument, the customer who ordered it, and sets this as an instance variable.  We've gone ahead and instantiated our first ZenClock, for our insomniac friend Roanoke.

Unfortunately, Roanoke won't be able to enjoy the fruits of his semi-conscious nocturnal mail-order adventure until we actually *build* his Zen Clock, and ship it to him.  But how do we do that?

```ruby
class ZenClock
  # ...

  def build!
    Bumbleworks.launch!('build_zen_clock', :parts => [:essence_of_time, :the_waterless_waterfall])
  end
end

# Receive the new order, and start the build process:
zen_clock = ZenClock.new(:roanoke)
zen_clock.build!
```

Now there's a `#build!` method, which is where we finally launch the process we defined earlier.  This `#build!` method, conceptually, "places a box of parts on the conveyor belt" (which, as you may recall, is step 2 in our original plan).  The second argument to `Bumbleworks.launch!` takes a hash, which ends up being the initial "payload" for the process.  In this case, we're providing the box of parts we'll need for assembling a Zen Clock.

We're doing great!  We received an order, and we placed a box of parts on the conveyor belt.  Now we'll just have our employees start building the.. oh, wait.  We forgot to hire employees.

## Hiring the Staff

The Zen Clock, being at once a highly technical affair and a pseudo-spiritual scam, will require both robots and real humans to build it.  Let's flesh out the `build_zen_clock` process by expanding our previous `make` step:

```ruby
Bumbleworks.define_process :name => 'build_zen_clock' do
  any_human :task => 'check_essence_of_time_for_leaks'
  smart_human :task => 'contemplate_solitude_of_static_universe'
  any_human :task => 'glue_parts_together'
  robot :task => 'add_batteries'
  ship
end
```

What's all this `:task => ...` nonsense?  In a Bumbleworks process plan, assigning an activity to a participant takes the following syntax:

```ruby
role :task => 'task_name'
```

When Bumbleworks is running a plan and encounters a line like this, it will place a Task in the queue, name it 'task_name', and make it available to any Users who possess the relevant role.  For those of you who pay attention to capitalization, you'll notice we introduced two concepts: Tasks and Users.  We'll look at Tasks first.

### The Bumbleworks Task

A Task (actually, Bumbleworks::Task) instance is a representation of a step on the assembly line that has to be completed by an "employee."  The conveyor belt stops temporarily until the activity is complete.

If we were building something useful, this might be something like carving, painting, cleaning, filling, soldering, et cetera.  In the case of the Zen Clock, the assembly line works like this:

  ```ruby
1.  any_human :task => 'check_essence_of_time_for_leaks'
2.  smart_human :task => 'contemplate_solitude_of_static_universe'
3.  any_human :task => 'glue_parts_together'
4.  robot :task => 'add_batteries'
  ```

1. The box of parts stops at a staffed workstation, where a lowly peon checks the Essence of Time part for leaks.  After verifying the part is intact, this peon pushes a button that starts the belt back up, moving the box of parts on to..

2. .. another workstation, this time staffed by a high-paid human with decades of spiritual experience (and a certificate of attendance from the 2004 Zen Conference at Universal Studios Hollywood).  This human spends several hours imbuing the box of parts with the Collected Wisdom of the Stillness of the Unchanging but Infinite Cosmos, then pushes a button that starts the belt back up, moving the box of parts on to..

3. .. the last human workstation, where a grizzled old human (whose hands were birthing foals before you were born) finally assembles the Clock, gradually becoming more and more convinced of its metaphysical qualities as the glue fumes rise.  The Clock is placed on the conveyor belt, a button is pushes, the belt starts back up, and we move on to our final destination..

4. .. a robot, whose only task is to insert the required fourteen AA batteries.  Because, yes, the Zen Clock *does* include batteries.

When a Bumbleworks process runs, it steps through the process definition sequentially (well, not always - but more about this later), and for each line it encounters, it:

1. Creates a task for the given role,
1. Waits for someone with that role to complete the task, and
1. Moves on to the next line

Remember when we added a `#build!` method to our ZenClock class, which in turn called `Bumbleworks.launch!` to start the build_zen_clock process?  As soon as that process starts, and the Bumbleworks parser hits the first line, a task (named "check_essence_of_time_for_leaks") is generated for the given role ("any_human") and dropped in the queue.  But who completes it?  Who is this mythical "any_human"?

### The Bumbleworks Role

