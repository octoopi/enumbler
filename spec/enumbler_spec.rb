# frozen_string_literal: true

# -----------------------------------------------------------------------------
# Schema and model definitions for our specs.
# -----------------------------------------------------------------------------
ActiveRecord::Schema.define do
  create_table :colors, force: true do |t|
    t.string :label, null: false
  end

  create_table :houses, force: true do |t|
    t.references :color, foreign_key: true, null: false
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

# Our Color has been Enumbled with some basic colors.
class Color < ApplicationRecord
  # @!parse extend Enumbler::ClassMethods
  include Enumbler

  enumble :black, 1
  enumble :white, 2
  enumble :dark_brown, 3
  enumble :infinity, 4, label: 'This is a made-up color'
end

# Our House class, it has a color of course!
class House < ApplicationRecord
  # @!parse extend Enumbler::ClassMethods
  include Enumbler
  enumbled_to :color
end

# -----------------------------------------------------------------------------
# Here are the expectations.  Note that `Color.seed_the_enumbler!` needs to be
# run to seed the database.  We are using transactions here so we need to run it
# each time.
# -----------------------------------------------------------------------------
RSpec.describe Enumbler do
  before(:example, :seed) do
    Color.seed_the_enumbler!
  end

  it 'has a version number' do
    expect(Enumbler::VERSION).not_to be nil
  end

  describe '#to_sym', :seed do
    it 'returns its own enum symbol' do
      expect(Color.black.enumble.enum).to eq :black
    end
  end

  describe '.enumble' do
    it 'raises an error when the same enumble is added twice' do
      expect { Color.enumble(:white, 1) }.to raise_error(Enumbler::Error, /twice/)
    end
    it 'creates the constants' do
      expect(Color::BLACK).to eq 1
      expect(Color::WHITE).to eq 2
    end
    it 'creates the class finder methods', :seed do
      expect(Color.black).to eq Color.find(Color::BLACK)
    end
    it 'creates the query methods', :seed do
      expect(Color.black).to be_black
      expect(Color.black.is_black).to be true
    end
  end

  describe '.enumbled_to', :seed do
    after(:example) { House.enumbled_to(:color) }
    it 'raises an error when the class does not exist' do
      expect { House.enumbled_to(:bob) }.to raise_error(Enumbler::Error, /cannot be found/)
    end
    it 'raises an error when the class is not enumbled' do
      class_double('MyFriendBob').as_stubbed_const
      expect { House.enumbled_to(:my_friend_bob) }.to raise_error(Enumbler::Error, /not have any enumbles/)
    end

    context 'when adding adds searchable scoped class method' do
      it 'queries based on the enumbler' do
        house = House.create! color: Color.black
        expect(House.color(1)).to contain_exactly(house)
        expect(House.color(:black)).to contain_exactly(house)
        expect(House.color(Color.black)).to contain_exactly(house)
      end
      it 'raises an error when the Enumble is not defined' do
        expect { House.color(100, 1) }.to raise_error(Enumbler::Error, /Unable to find/)
      end
      it 'allows a prefix to be set' do
        house = House.create! color: Color.black
        House.enumbled_to(:color, prefix: 'where_by')
        expect(House.where_by_color(:black)).to contain_exactly(house)
      end
    end
  end

  describe '.enumbles', :seed do
    it 'contains the enumbles' do
      expect(Color.enumbles.map(&:id)).to contain_exactly(1, 2, 3, 4)
    end

    it 'sorts' do
      expect(Color.enumbles.reverse.first).to eq Color.infinity.enumble
    end
  end

  describe '.ids_from_enumablable', :seed do
    it 'returns a numeric id' do
      expect(Color.ids_from_enumablable(1)).to contain_exactly(1)
    end
    it 'raises an error when the id is not defined' do
      expect { Color.ids_from_enumablable(100, 1) }.to raise_error(Enumbler::Error, /Unable to find/)
    end
    it 'returns an id from a symbol' do
      expect(Color.ids_from_enumablable(:black)).to contain_exactly(1)
      expect(Color.ids_from_enumablable(:black, :white)).to contain_exactly(1, 2)
    end
    it 'raises an error when the symbol cannot be found' do
      expect { Color.ids_from_enumablable(:Bob) }.to raise_error(Enumbler::Error, /Unable to find/)
    end
    it 'returns an id from a instance' do
      expect(Color.ids_from_enumablable(Color.black)).to contain_exactly(1)
    end
    it 'raises an error when the symbol cannot be found' do
      expect { Color.ids_from_enumablable(Color.new(id: 100, label: 'ok')) }
        .to raise_error(Enumbler::Error, /Unable to find/)
    end
  end

  describe '.seed_the_enumbler', :seed do
    it 'uses a custom label' do
      expect(Color.infinity.label).to eq 'This is a made-up color'
    end
    it 'updates the records' do
      Color.enumble :pink, 8

      Color.create!(id: 5, label: 'this is not to be kept')
      Color.seed_the_enumbler!

      expect(Color.pink).to eq Color.find(8)
      expect(Color.find_by(id: 5)).to be_nil
      Color.enumbles.pop
    end
  end
end
