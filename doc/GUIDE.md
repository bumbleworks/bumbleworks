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

Looks great!  Now, given that we're agile, and extreme, and cross-country-functional, and 2.0, let's just go ahead and start building our factory - we'll develop it iteratively.  For now, we'll ignore steps 5 and 6, mostly because we're in denial.

In Bumbleworks, our plan might look something like this:

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

A Task (actually, Bumbleworks::Task) instance is a representation of 

