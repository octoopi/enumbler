# frozen_string_literal: true

module Enumbler
  # Extending this module bestows the power of the `enumbler` to the underlying
  # model.  For example, if you have a model `Color` you would include the
  # `Enabler` to support the different colors your `Color` model represents.
  module Enabler
    extend ActiveSupport::Concern

    # The Enumble definition that this record defined.
    # @return [Enumbler::Enumble]
    def enumble
      @enumble = self.class.enumbles.find { |enumble| enumble.id == id }

      raise Error, 'An enumble is not defined for this record!' if @enumble.nil?

      @enumble
    end

    # These ClassMethods can be included in any model that you wish to
    # _Enumble_!
    #
    #   class Color < ApplicationRecord
    #     include Enumbler::Enabler
    #
    #     enumble :black, 1
    #     enumble :white, 2
    #   end
    #
    module ClassMethods
      attr_reader :enumbles

      # Defines an Enumble for this model.  An enum with integrity.
      #
      #   # in your migration
      #   create_table :colors, force: true do |t|
      #     t.string :label, null: false, index: { unique: true }
      #   end
      #
      #   class Color < ApplicationRecord
      #     include Enumbler::Enabler
      #
      #     enumble :black, 1
      #     enumble :white, 2
      #     enumble :dark_brown, 3, # label: 'dark-brown'
      #     enumble :black_hole, 3, label: 'Oh my! It is a black hole!'
      #   end
      #
      #   # Dynamically adds the following methods:
      #   Color::BLACK   #=> 1
      #   Color.black    #=> Color.find(1)
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
        @enumbler_label_column_name ||= :label

        enumble = Enumble.new(enum, id, label: label, label_column_name: @enumbler_label_column_name, **options)

        if @enumbles.include?(enumble)
          raise Error, "You cannot add the same Enumble twice! Attempted to add: #{enum}, #{id}."
        end

        define_dynamic_methods_and_constants_for_enumbled_model(enum, id)

        @enumbles << enumble
      end

      # By default, the Enumbler is expecting a table with an underlying column
      # named `label` that represents the enum in the database.  You can change
      # this by calling `enumber_label_column_name` before you `enumble`!
      #
      #   ActiveRecord::Schema.define do
      #     create_table :feelings, force: true do |t|
      #       t.string :emotion, null: false, index: { unique: true }
      #     end
      #   end
      #
      #   class Feeling < ApplicationRecord
      #     # @!parse extend Enumbler::Enabler::ClassMethods
      #     include Enumbler::Enabler
      #
      #     enumbler_label_column_name :emotion
      #
      #     enumble :sad, 1
      #     enumble :happy, 2
      #     enumble :verklempt, 3, label: 'overcome with emotion'
      #   end
      def enumbler_label_column_name(label_column_name)
        @enumbler_label_column_name = label_column_name
      end

      # Return the record id for a given argument.  Can accept an Integer, a
      # Symbol, or an instance of Enumbled model.  This lookup is a database-free
      # lookup.
      #
      #   Color.id_from_enumbler(1) # => 1
      #   Color.id_from_enumbler(:black) # => 1
      #   Color.id_from_enumbler(Color.black) # => 1
      #
      # @raise [Error] when there is no enumble to be found
      # @param arg [Integer, Symbol, Class]
      # @return [Integer]
      def id_from_enumbler(arg)
        ids_from_enumbler(arg).first
      end

      # Return the record id(s) based on different argument types.  Can accept
      # an Integer, a Symbol, or an instance of Enumbled model.  This lookup is
      # a database-free lookup.
      #
      #   Color.ids_from_enumbler(1, 2) # => [1, 2]
      #   Color.ids_from_enumbler(:black, :white) # => [1, 2]
      #   Color.ids_from_enumbler(Color.black, Color.white) # => [1, 2]
      #
      # @raise [Error] when there is no enumble to be found
      # @param *args [Integer, Symbol, Class]
      # @return [Array<Integer>]
      def ids_from_enumbler(*args)
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

      # Seeds the database with the Enumbler data.
      # @param delete_missing_records [Boolean] remove any records that are no
      #   longer defined (default: false)
      # @param validate [Boolean] validate on save?
      def seed_the_enumbler(delete_missing_records: false, validate: true)
        max_database_id = all.order('id desc').take&.id || 0
        max_enumble_id = enumbles.map(&:id).max

        # If we are not deleting records, we just need to update each listed
        # enumble and skip anything else in the database.  If we are deleting
        # records, we need to know the max database id.
        iterator = if !delete_missing_records
                     @enumbles.map(&:id)
                   elsif max_enumble_id > max_database_id
                     (1..max_enumble_id)
                   else
                     (1..max_database_id)
                   end

        discarded_ids = []

        iterator.each do |id|
          enumble = @enumbles.find { |e| e.id == id }

          if enumble.nil?
            discarded_ids << id
            next
          end

          record = find_or_initialize_by(id: id)
          record.attributes = enumble.attributes
          record.save!(validate: validate)
        end

        where(id: discarded_ids).delete_all if delete_missing_records
      end

      # Seeds the database with the Enumble data, removing any records that are no
      # longer defined.
      # @param validate [Boolean] validate on save?
      def seed_the_enumbler!(validate: true)
        seed_the_enumbler(delete_missing_records: true, validate: validate)
      end

      private

      def define_dynamic_methods_and_constants_for_enumbled_model(enum, id)
        method_name = "#{enum}?"
        not_method_name = "not_#{enum}?"
        alias_method_name = "is_#{enum}"

        const_set(enum.to_s.upcase, id)
        define_method(method_name) { self.id == id }
        define_method(not_method_name) { self.id != id }
        alias_method alias_method_name, method_name
        define_singleton_method(enum) { find(id) }
      end
    end
  end
end
