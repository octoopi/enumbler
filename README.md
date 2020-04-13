# Enumbler

`Enums` are terrific, but they lack integrity.  Enumbler! The _enum enabler_!  The goal is to allow one to maintain a true foreign_key database driven relationship that also behaves a little bit like an `enum`.  Best of both worlds?  We hope so.


## Example

Suppose you have a `House` and you want to add some `colors` to the house.  You are tempted to use an `enum` but the `Enumbler` is calling!

```ruby
ActiveRecord::Schema.define do
  create_table :colors|t|
    t.string :label, null: false
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

  enumble :black, 1
  enumble :white, 2
  enumble :dark_brown, 3
  enumble :infinity, 4, label: 'Infinity - and beyond!'
end

# Our House class, it has a color of course!
class House < ApplicationRecord
  enumbled_to :color
end

# This gives you some power:
Color::BLACK           # => 1
Color.black            # => equivalent to Color.find(1)
Color.black.black?     # => true
Color.black.is_black   # => true
Color.white.not_black? # => true

house = House.create!(color: Color.black)
house.black?
house.not_black?

House.color(:black) # => [house]
```

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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Roadmap

Ideally, we could make this work more like a traditional `enum`; for example, overriding the `.where` method by allowing something like: `House.where(color: :blue)` instead of `House.where_color(:blue)`.  But right now am in a rush and not sure how to go about doing that properly.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/linguabee/enumbler.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
