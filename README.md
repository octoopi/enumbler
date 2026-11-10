# Enumbler

`Enums` are terrific, but they lack integrity.  Enumbler! The _enum enabler_!  The goal is to allow one to maintain a true foreign_key database driven relationship that also behaves a little bit like an `enum`.  Best of both worlds?  We hope so.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'enumbler'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install enumbler

## Usage

Suppose you have a `House` and you want to add some `colors` to the house.  You are tempted to use an `enum` but the `Enumbler` is calling!

```ruby
ActiveRecord::Schema.define do
  create_table :colors do |t|
    t.string :label, null: false, index: { unique: true }
    t.string :hex, null: true
  end

  create_table :houses do |t|
    t.references :color, foreign_key: true, null: false
  end
end

class ApplicationRecord < ActiveRecord::Base
  include Enumbler
  self.abstract_class = true
end

# Our Color has been Enumbled with some basic colors.
class Color < ApplicationRecord
  include Enumbler::Enabler

  enumble :black, 1, hex: '000000'
  enumble :white, 2, hex: 'ffffff'
  enumble :dark_brown, 3
  enumble :infinity, 4, label: 'Infinity - and beyond!'
end

# Our House class, it has a color of course!
class House < ApplicationRecord
  enumbled_to :color
end

# This gives you some power:
Color::BLACK               # => 1
Color.black                # => equivalent to Color.find(1)
Color.black.black?         # => true
Color.black.is_black       # => true
Color.white.not_black?     # => true

Color.all.any_black?                         # => true
Color.where.not(id: Color::BLACK).any_black? # => false

# Get attributes without hitting the database
Color.black(:id)           # => 1
Color.black(:enum)         # => :black
Color.black(:label)        # => 'black'
Color.black(:graphql_enum) # => 'BLACK'

# Get an Enumble object from an id, label, enum, or ActiveRecord model
Color.find_enumbles(:black, 'white') # => [Enumbler::Enumble<:black>, Enumbler::Enumble<:white>]
Color.find_enumbles(:black, 'does-not-exist') # => [Enumbler::Enumble<:black>, nil]

Color.find_enumble(:black) # => Enumbler::Enumble<:black>

# Is pretty flexible with findidng things from strings
Color.find_enumble('Dark_Brown') # => Enumbler::Enumble<:dark-brown>

# raises errors if none found
Color.find_enumbles!(:black, 'does-no-exist') # => raises Enumbler::Error
Color.find_enumble!(:does_not_exist) # => raises Enumbler::Error

# Get ids flexibly, without raising an error if none found
Color.ids_from_enumbler(:black, 'white') # => [1, 2]
Color.ids_from_enumbler(:black, 'does-no-exist') # => [1, nil]

# Raise an error if none found
Color.ids_from_enumbler!(:black, 'does-no-exist') # => raises Enumbler::Error
Color.id_from_enumbler!(:does_not_exist) # => raises Enumbler::Error

# Get a model instance (like `.find_by` in Rails)
Color.find_by_enumble(1)
Color.find_by_enumble(:black)
Color.find_by_enumble("black")
Color.find_by_enumble("BLACK")
Color.find_by_enumble(Color.black) # => self
Color.find_by_enumble("whoops")    # => nil

# Raise ActiveRecord::RecordNotFound error with bang
Color.find_by_enumble!("whoops")    # => nil

# Get enumble object by id
house = House.create!(color: Color.black)

# These are all db-free lookups
house.color_label        # => 'black'
house.color_enum         # => :black
house.color_graphql_enum # => 'BLACK'
house.black?             # => true
house.not_black?         # => false

house2 = House.create!(color: Color.white)
House.color(:black, :white)      # => ActiveRecord::Relation<house, house2>
House.color(Color.black, :white) # => ActiveRecord::Relation<house, house2>
```

### Use a column other than `label`

By default, the Enumbler expects a table in the database with a column `label`.  However, you can change this to another underlying column name.  Note that the enumbler still treats it as a `label` column; however it will be saved to the correct place in the database. Your model now can have its own `label` separate from whatever attribute/column was
specified for Enumbler usage.

```ruby
ActiveRecord::Schema.define do
  create_table :feelings, force: true do |t|
    t.string :emotion, null: false, index: { unique: true }
    t.string :label
  end
end

class Feeling < ApplicationRecord
  # @!parse extend Enumbler::Enabler::ClassMethods
  include Enumbler::Enabler

  enumbler_label_column_name :emotion

  enumble :sad, 1
  enumble :happy, 2
  enumble :verklempt, 3, label: "Verklempt!", emotion: 'overcome with emotion'
end

# Now the `Feeling` model can use `label` if it wants to
# and not conflict with Enumbler usage (:emotion in this case)
# .enumble.label & .emotion is used internally by Enumbler
Feeling.verklempt.label           # => 'Verklempt!'
Feeling.verklempt.enumble.label   # => 'overcome with emotion'
Feeling.verklempt.emotion         # => 'overcome with emotion'
```

### Allow duplicate labels

Every enumble in a model normally needs a unique id, enum, **and** label: a second `enumble` that repeats any of the three raises `You cannot add the same Enumble twice!`.  When labels genuinely repeat, say a `Topic` table where "Classroom" appears under two different parents, opt the model in with `enumbler_allow_duplicate_labels` before its first `enumble`:

```ruby
ActiveRecord::Schema.define do
  create_table :topics, force: true do |t|
    t.string :label, null: false # no unique index: labels repeat
  end
end

class Topic < ApplicationRecord
  include Enumbler::Enabler

  enumbler_allow_duplicate_labels

  enumble :k12_classroom, 17, label: "Classroom"
  enumble :higher_ed_classroom, 34, label: "Classroom"
  enumble :science, 20, label: "Science"
end
```

With it on, an enumble is a duplicate only when its **id or enum** is already taken.  Enum names are still unique, so constants (`Topic::K12_CLASSROOM`), class shortcuts (`Topic.k12_classroom`), predicates (`topic.k12_classroom?`), `graphql_enum`, and lookups by id, symbol, Enumble, or record all work as before.  Two Enumbles that share only a label are no longer `==`.

String lookups (`find_enumble(s)`, `find_by_enumble`, `ids_from_enumbler`, the `enumbled_to` scopes, and their bang versions) become stricter:

```ruby
Topic.find_enumble("higher_ed_classroom") # => Enumbler::Enumble<:higher_ed_classroom>, an enum name always wins
Topic.find_enumble("Science")             # => Enumbler::Enumble<:science>, one label match resolves
Topic.find_enumble("Art")                 # => nil, as before
Topic.find_enumble("Classroom")           # => raises Enumbler::AmbiguousLabelError
Lesson.topic("Classroom")                 # => raises Enumbler::AmbiguousLabelError (Lesson `enumbled_to :topic`)
```

A String that matches more than one label raises `Enumbler::AmbiguousLabelError` (a subclass of `Enumbler::Error`) **whether or not** you asked for an error on a missing value, rather than silently returning whichever enumble was defined first.  `find_by_enumble` lets it through instead of turning it into `ActiveRecord::RecordNotFound`.  Matching follows `case_sensitive:` as usual, so `"classroom"` is ambiguous too unless you pass `case_sensitive: true`.

Models that do not call `enumbler_allow_duplicate_labels` behave exactly as they always have.

## Core ext

Adds case equality power to the `Symbol` class allowing you to use case methods directly against an enabled instance:

```ruby
case Color.black
when :black
  'not surprised'
when :blue, :purple
  'very surprised'
end
```

## Suppressing database warnings

When an `enumble` defines extra attributes, the Enumbler verifies them against the model's table at class-load time.  If the table cannot be inspected — for example, while your test databases are dropped mid-way through a `rake parallel:setup` — it prints an `[Enumbler Warning]` for every affected model rather than raising.  If those warnings are just noise in your workflow, you can suppress them:

```ruby
Enumbler.suppress_database_warnings = true
```

Or set the environment variable `ENUMBLER_SUPPRESS_DATABASE_WARNINGS` to any non-empty value — handy for wrapping database reset commands:

```bash
ENUMBLER_SUPPRESS_DATABASE_WARNINGS=1 bundle exec rake parallel:setup
```

The Ruby-level setting, when assigned, takes precedence over the environment variable.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Branching (modified git flow)

Day-to-day work follows git flow: feature/bug/chore branches come off `develop` and are merged back into `develop` via PR. Releases move `develop` into `main` through a `release/x.y.z` branch (or a `hotfix/x.y.z` branch off `main` for urgent fixes), and after tagging, the tag is merged back into `develop` so both branches share the release commit.

### Releasing a New Version

A release is triggered by pushing a **version tag** to GitHub: the `CI Matrix Testing` workflow runs the rspec matrix and, if green, the `Publish Gem` job builds the gem and pushes it to [rubygems.org](https://rubygems.org).

Two things to know before tagging:

1. The published version comes from `lib/enumbler/version.rb`, **not** the tag name — make sure they match (the tag is bare, no `v` prefix: `0.10.0`).
2. RubyGems rejects duplicate versions, so every release needs a version bump.

Steps:

1. Bump `Enumbler::VERSION` in `lib/enumbler/version.rb` and add its section to `CHANGELOG.md`, then refresh every lockfile so it records the new version (`for g in Gemfile Gemfile.rails*[0-9]; do BUNDLE_GEMFILE=$g bundle lock; done`) on a `release/x.y.z` branch off `develop` (or `hotfix/x.y.z` off `main`).
2. Merge the branch into `main`, then tag the release commit:

   ```bash
   git checkout main && git pull
   git tag -a 0.10.0 -m "Release 0.10.0"
   git push origin main 0.10.0
   ```

3. Watch the `CI Matrix Testing` workflow on the tag: when the publish job is green, confirm the new version on [rubygems.org](https://rubygems.org/gems/enumbler).
4. Merge the tag back into `develop`: `git checkout develop && git merge 0.10.0 && git push`.

### Matrix testing

The gem supports Ruby >= 3.2 and ActiveRecord/ActiveSupport >= 6.0, < 9.  CI runs the rspec matrix across those using one `Gemfile.rails*` per Rails minor (6.0 through 8.1); the main `Gemfile` tracks the newest Rails.  To test against one of them locally, run:

```bash
BUNDLE_GEMFILE=Gemfile.rails7.2 bundle install
BUNDLE_GEMFILE=Gemfile.rails7.2 bundle exec rspec
```

## Roadmap

* Ideally, we could make this work more like a traditional `enum`; for example, overriding the `.where` method by allowing something like: `House.where(color: :blue)` instead of `House.color(:blue)`.  But right now am in a rush and not sure how to go about doing that properly.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/octoopi/enumbler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
