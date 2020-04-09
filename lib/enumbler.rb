# frozen_string_literal: true

require 'enumbler/enumble'
require 'enumbler/version'

require 'active_support/concern'
require 'active_support/inflector'

# The Enumbler add integrity to our enum implementation!
module Enumbler
  extend ActiveSupport::Concern

  class Error < StandardError; end

  # The Enumble definition that this record defined.
  # @return [Enumbler::Enumble]
  def enumble
    @enumble = self.class.enumbles.find { |enumble| enumble.id == id }

    raise Error, 'An enumble is not defined for this record!' if @enumble.nil?

    @enumble
  end

  # These are the ClassMethods that are added to an ApplicationRecord model when
  # `include Enumbler` is added to the class.
  module ClassMethods
    attr_reader :enumbles

    # Defines an Enumble for this model.  An enum with integrity.
    #
    #   # in your migration
    #   create_table :colors, force: true do |t|
    #     t.string :label, null: false
    #   end
    #
    #   class Color < ApplicationRecord
    #     include Enumbler
    #
    #     enumble :black, 1
    #     enumble :white, 2
    #     enumble :dark_brown, 3, # label: 'dark-brown'
    #     enumble :black_hole, 3, label: 'Oh my! It is a black hole!'
    #   end
    #
    #   # Dynamically adds the following methods:
    #   Color::BLACK   #=> 1
    #   Color.black    #=> MyRecord.find(1)
    #   color.black?   #=> true || false
    #   color.is_black #=> true || false
    #
    # @param enum [Symbol] the enum representation
    # @param id [Integer] the primary key value
    # @param label [String] optional: label for humans
    # @param **options [Hash] optional: additional attributes and values that
    #   will be saved to the database for this enumble record
    def enumble(enum, id, label: nil, **options)
      @enumbles ||= []
      @enumbled_model = self

      enumble = Enumble.new(enum, id, label: label, **options)

      if @enumbles.include?(enumble)
        raise Error, "You cannot add the same Enumble twice! Attempted to add: #{enum}, #{id}."
      end

      define_dynamic_methods_and_constants_for_enumbled_model(enum, id)

      @enumbles << enumble
    end

    # Defines the relationship between a model and the Enumbled class.  Use this
    # in lieu of `belongs_to` to establish that relationship.  It requires a
    # model that has defined one or more `Enumbles`.
    #
    #   # in your migration
    #   create_table :houses, force: true do |t|
    #     t.references :color, foreign_key: true, null: false
    #   end
    #
    #   class House < ApplicationRecord
    #     include Enumbler
    #     enumbled_to :color
    #   end
    #
    # @param name [Symbol] symbol representation of the class this belongs_to
    # @param *args [Array] additional arguments passed to `belongs_to`
    def enumbled_to(name, scope = nil, prefix: nil, **options)
      class_name = name.to_s.classify
      @enumbled_model = class_name.constantize

      unless @enumbled_model.respond_to?(:enumbles)
        raise Error, "The class #{class_name} does not have any enumbles defined."\
          " You can add them via `#{class_name}.enumble :blue, 1`."
      end

      belongs_to(name, scope, **options)

      define_dynamic_methods_for_enumbled_to_models(prefix: prefix)
    rescue NameError
      raise Error, "The class #{class_name} cannot be found.  Uninitialized constant."
    end

    # Return the record id(s) based on different argument types.  Can accept an
    # Integer, a Symbol, or an instance of Enumbled model.  This lookup is a
    # databse-free lookup.
    #
    #   Color.ids_from_enumablable(1, 2) # => [1, 2]
    #   Color.ids_from_enumablable(:black, :white) # => [1, 2]
    #   Color.ids_from_enumablable(Color.black, Color.white) # => [1, 2]
    #
    # @raise [Error] when there is no enumble to be found
    # @param *args [Integer, Symbol, Class]
    # @return [Array<Integer>]
    def ids_from_enumablable(*args)
      args.flatten.compact.uniq.map do |arg|
        err = "Unable to find a #{@enumbled_model}#enumble with #{arg}"

        begin
          arg = Integer(arg) # raises Type error if not a real integer
          enumble = @enumbled_model.enumbles.find { |e| e.id == arg }
        rescue TypeError
          enumble = if arg.is_a?(Symbol)
                      @enumbled_model.enumbles.find { |e| e.enum == arg }
                    elsif arg.instance_of?(@enumbled_model)
                      arg.enumble
                    end
        end

        enumble&.id || raise(Error, err)
      rescue Error
        raise Error, err
      end
    end

    # Seeds the database with the Enumble data.
    # @param delete_missing_records [Boolean] remove any records that are no
    #   longer defined (default: false)
    def seed_the_enumbler(delete_missing_records: false)
      max_database_id = all.order('id desc').take&.id || 0
      max_enumble_id = enumbles.map(&:id).max

      max_id = max_enumble_id > max_database_id ? max_enumble_id : max_database_id

      discarded_ids = []

      (1..max_id).each do |id|
        enumble = @enumbles.find { |e| e.id == id }

        if enumble.nil?
          discarded_ids << id
          next
        end

        record = find_or_initialize_by(id: id)
        record.attributes = enumble.attributes
        record.save!
      end

      where(id: discarded_ids).delete_all if delete_missing_records
    end

    # Seeds the database with the Enumble data, removing any records that are no
    # longer defined.
    def seed_the_enumbler!
      seed_the_enumbler(delete_missing_records: true)
    end

    private

    def define_dynamic_methods_and_constants_for_enumbled_model(enum, id)
      method_name = "#{enum}?"
      alias_method_name = "is_#{enum}"

      const_set(enum.to_s.upcase, id)
      define_method(method_name) { self.id == id }
      alias_method alias_method_name, method_name
      define_singleton_method(enum) { find(id) }
    end

    def define_dynamic_methods_for_enumbled_to_models(prefix: nil)
      model_name = @enumbled_model.to_s.underscore

      method = if prefix.blank?
                 model_name
               else
                 "#{prefix}_#{model_name}"
               end

      define_singleton_method(method) do |*args|
        where("#{model_name}_id": ids_from_enumablable(args))
      end
    end
  end
end
