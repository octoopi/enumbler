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
  create_table :colors|t|
    t.string :label, null: false, index: { unique: true }
    t.string :hex, null: true
  end

  create_table :houses|t|
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
Color.find_enumbles!!(:black, 'does-no-exist') # => raises Enumbler::Error
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Roadmap

* Ideally, we could make this work more like a traditional `enum`; for example, overriding the `.where` method by allowing something like: `House.where(color: :blue)` instead of `House.color(:blue)`.  But right now am in a rush and not sure how to go about doing that properly.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/linguabee/enumbler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
