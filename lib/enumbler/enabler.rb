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
      @enumble = self.class.find_enumble(id)

      raise Error, 'An enumble is not defined for this record!' if @enumble.nil?

      @enumble
    end

    # The enumble label if it exists.
    # @return [String]
    def to_s
      enumble = self.class.find_enumble(id)
      return enumble.label if enumble.present?

      super
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
      #     enumble :black, 1, hex: '000000'
      #     enumble :white, 2, hex: 'ffffff'
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
      # @param **attributes [Hash] optional: additional attributes and values that
      #   will be saved to the database for this enumble record
      def enumble(enum, id, label: nil, **attributes)
        raise_error_if_model_does_not_support_attributes(attributes)

        id = validate_id_is_numeric(enum, id)

        @enumbles ||= Enumbler::Collection.new
        @enumbled_model = self
        @enumbler_label_column_name ||= :label

        enumble = Enumble.new(enum, id, label: label, label_column_name: @enumbler_label_column_name, **attributes)

        if @enumbles.include?(enumble)
          raise Error, "You cannot add the same Enumble twice! Attempted to add: #{enum}, #{id}."
        end

        define_dynamic_methods_and_constants_for_enumbled_model(enumble)

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

      # See {.find_enumbles}.  Simply returns the first object.  Use when you
      # want one argument to be found and not returned in an array.
      # @raise [Error] when there is no [Enumbler::Enumble] to be found and
      #   `raise_error: true`
      # @param args [Integer, String, Symbol]
      # @param case_sensitive [Boolean] should a String search be case sensitive
      #   (default: false)
      # @param raise_error [Boolean] raise an error if not found (default:
      #   false)
      # @return [Enumbler::Enumble]
      def find_enumble(arg, case_sensitive: false, raise_error: false)
        find_enumbles(arg, case_sensitive: case_sensitive, raise_error: raise_error).first
      end

      # See {.find_enumbles}.  Simply returns the first object.  Use when you
      # want one argument to be found and not returned in an array. Raises error
      # if none found.
      # @raise [Error] when there is no [Enumbler::Enumble] to be found and
      #   `raise_error: true`
      # @param args [Integer, String, Symbol]
      # @param case_sensitive [Boolean] should a String search be case sensitive
      #   (default: false)
      # @return [Enumbler::Enumble]
      def find_enumble!(arg, case_sensitive: false)
        find_enumbles(arg, case_sensitive: case_sensitive, raise_error: true).first
      end

      # Finds an array of {Enumbler::Enumble} objects matching the given
      # argument. Accepts an Integer, String, Symbol, or ActiveRecord instance.
      #
      # This method is designed to let you get information about the record
      # without having to hit the database.  Returns `nil` when none found
      # unless `raise_error` is `true`.
      #
      #    Color.find_enumbles(:black, 'white', 'not-found')
      #      #=> [Enumbler::Enumble<:black>, Enumbler::Enumble<:white>, nil]
      #
      # @raise [Error] when there is no [Enumbler::Enumble] to be found and
      #   `raise_error: true`
      # @param args [Integer, String, Symbol]
      # @param case_sensitive [Boolean] should a String search be case sensitive
      #   (default: false)
      # @param raise_error [Boolean] raise an error if not found (default:
      #   false)
      # @return [Array<Enumbler::Enumble>]
      def find_enumbles(*args, case_sensitive: false, raise_error: false)
        args.flatten.compact.uniq.map do |arg|
          err = "Unable to find a #{@enumbled_model}#enumble with #{arg}"

          begin
            arg = Integer(arg) # raises Type error if not a real integer
            enumble = @enumbled_model.enumbles.find { |e| e.id == arg }
          rescue TypeError, ArgumentError
            enumble =
              if arg.is_a?(Symbol)
                @enumbled_model.enumbles.find { |e| e.enum == arg }
              elsif arg.is_a?(String)
                @enumbled_model.enumbles.find do |e|
                  if case_sensitive
                    [e.label, e.enum.to_s].include?(arg)
                  else
                    arg.casecmp?(e.label) || arg.casecmp?(e.enum.to_s)
                  end
                end
              elsif arg.instance_of?(@enumbled_model)
                arg.enumble
              end
          end

          if enumble.present?
            enumble
          else
            raise Error if raise_error

            nil
          end
        rescue Error
          raise Error, err
        end
      end

      # See {.find_enumbles}.  Same method, only raises error when none found.
      # @raise [Error] when there is no [Enumbler::Enumble] to be found
      # @param args [Integer, String, Symbol]
      # @param case_sensitive [Boolean] should a String search be case sensitive
      #   (default: false)
      # @return [Array<Enumbler::Enumble>]
      def find_enumbles!(*args, case_sensitive: false)
        find_enumbles(*args, case_sensitive: case_sensitive, raise_error: true)
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
      # @param case_sensitive [Boolean] should a string search be performed with
      #   case sensitivity (default: false)
      # @param raise_error [Boolean] raise an error if not found (default:
      #   false)
      # @return [Integer]
      def id_from_enumbler(arg, case_sensitive: false, raise_error: false)
        ids_from_enumbler(arg, case_sensitive: case_sensitive, raise_error: raise_error).first
      end

      # See {.ids_from_enumbler}.  Raises error if none found.
      # @raise [Error] when there is no enumble to be found
      # @param arg [Integer, Symbol, Class]
      # @param case_sensitive [Boolean] should a string search be performed with
      #   case sensitivity (default: false)
      # @param raise_error [Boolean] raise an error if not found (default:
      #   false)
      # @return [Integer]
      def id_from_enumbler!(arg, case_sensitive: false)
        ids_from_enumbler(arg, case_sensitive: case_sensitive, raise_error: true).first
      end

      # Return the record id(s) based on different argument types.  Can accept
      # an Integer, a Symbol, or an instance of Enumbled model.  This lookup is
      # a database-free lookup.
      #
      #   Color.ids_from_enumbler(1, 2) # => [1, 2]
      #   Color.ids_from_enumbler(:black, :white) # => [1, 2]
      #   Color.ids_from_enumbler('black', :white) # => [1, 2]
      #   Color.ids_from_enumbler(Color.black, Color.white) # => [1, 2]
      #
      # @raise [Error] when there is no enumble to be found
      # @param *args [Integer, Symbol, Class]
      # @param case_sensitive [Boolean] should a string search be performed with
      #   case sensitivity (default: false)
      # @param raise_error [Boolean] raise an error if not found (default:
      #   false)
      # @return [Array<Integer>]
      def ids_from_enumbler(*args, case_sensitive: false, raise_error: false)
        enumbles = find_enumbles(*args, case_sensitive: case_sensitive, raise_error: raise_error)
        enumbles.map { |e| e&.id }
      end

      # See {.ids_from_enumbler}.  Raises error when none found.
      # @raise [Error] when there is no enumble to be found
      # @param *args [Integer, Symbol, Class]
      # @param case_sensitive [Boolean] should a string search be performed with
      #   case sensitivity (default: false)
      # @return [Array<Integer>]
      def ids_from_enumbler!(*args, case_sensitive: false)
        enumbles = find_enumbles!(*args, case_sensitive: case_sensitive)
        enumbles.map(&:id)
      end

      # Seeds the database with the Enumbler data.
      # @param delete_missing_records [Boolean] remove any records that are no
      #   longer defined (default: false)
      # @param validate [Boolean] validate on save?
      def seed_the_enumbler(delete_missing_records: false, validate: true)
        max_database_id = all.order('id desc').take&.id || 0
        max_enumble_id = @enumbles.map(&:id).max

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

      def define_dynamic_methods_and_constants_for_enumbled_model(enumble)
        method_name = "#{enumble.enum}?"
        not_method_name = "not_#{enumble.enum}?"
        alias_method_name = "is_#{enumble.enum}"

        const_set(enumble.enum.to_s.upcase, enumble.id)
        define_method(method_name) { id == enumble.id }
        define_method(not_method_name) { id != enumble.id }
        alias_method alias_method_name, method_name
        define_singleton_method(enumble.enum) do |attr = nil|
          return find(enumble.id) if attr.nil?

          enumble.send(attr)
        rescue NoMethodError
          raise Enumbler::Error, "The attribute #{attr} is not supported on this Enumble."
        end
      end

      # I accidentally forgot to provide an id one time and it was confusing as
      # the last argument became the hash of options.  This should help.
      def validate_id_is_numeric(enum, id)
        Integer(id)
      rescue ArgumentError, TypeError
        raise Enumbler::Error,
          "You must provide a numeric primary key, like: `enumble :#{enum}, 1 `"
      end

      def raise_error_if_model_does_not_support_attributes(attributes)
        return if attributes.blank?

        unsupported_attrs = attributes.reject { |key, _value| has_attribute?(key) }

        return if unsupported_attrs.blank?

        raise Enumbler::Error,
          "The model #{self} does not support the attribute(s): #{unsupported_attrs.keys.map(&:to_s).to_sentence}"
      rescue ActiveRecord::StatementInvalid
        warn "[Enumbler Warning] => Unable to find a table for #{self}."\
          'This is to be expected if there is a pending migration; however, if there is not then something is amiss.'
      end
    end
  end
end
