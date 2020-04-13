# frozen_string_literal: true

module Enumbler
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
      #     t.string :label, null: false
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

        enumble = Enumble.new(enum, id, label: label, **options)

        if @enumbles.include?(enumble)
          raise Error, "You cannot add the same Enumble twice! Attempted to add: #{enum}, #{id}."
        end

        define_dynamic_methods_and_constants_for_enumbled_model(enum, id)

        @enumbles << enumble
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
