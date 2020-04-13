# frozen_string_literal: true

require 'enumbler/enumble'
require 'enumbler/enabler'
require 'enumbler/version'

require 'active_support/concern'
require 'active_support/inflector'

# The Enumbler add integrity to our enum implementation!
module Enumbler
  extend ActiveSupport::Concern

  # An error raised by the Enumbler.
  class Error < StandardError; end

  # Include these ClassMethods in your base ApplicationRecord model to bestow
  # any of your models with the ability to be connected to an Enumbled relation
  # in the same way you would use `belongs_to` now you use `enumbled_to`.
  #
  #   class ApplicationRecord > ActiveRecord::Base
  #     include Enumbler
  #     self.abstract_class = true
  #   end
  #
  #   class House < ApplicationRecord
  #     enumbled_to :color
  #   end
  #
  module ClassMethods
    # Defines the relationship between a model and the Enumbled class.  Use this
    # in lieu of `belongs_to` to establish that relationship.  It requires a
    # model that has defined one or more `Enumbles`.
    #
    #   # in your migration
    #   create_table :houses, force: true do |t|
    #     t.references :color, foreign_key: true, null: false
    #   end
    #
    #   class ApplicationRecord > ActiveRecord::Base
    #     include Enumbler
    #     self.abstract_class = true
    #   end
    #
    #   class House < ApplicationRecord
    #     enumbled_to :color
    #   end
    #
    # @param name [Symbol] symbol representation of the class this belongs_to
    # @param prefix [Boolean] default: false; prefix the instance method
    #   attributes with the Enumble name, ex: `House.color_black?` instead of
    #   `House.black?`
    # @param scope_prefix [string] optional, prefix the class scopes, for
    #   example: `where_by` will make it `House.where_by_color(:black)`
    # @param **options [Hash] additional options passed to `belongs_to`
    def enumbled_to(name, scope = nil, prefix: false, scope_prefix: nil, **options)
      class_name = name.to_s.classify
      enumbled_model = class_name.constantize

      unless enumbled_model.respond_to?(:enumbles)
        raise Error, "The model #{class_name} does not have any enumbles defined."\
          " You can add them via `#{class_name}.enumble :blue, 1`."
      end

      belongs_to(name, scope, **options)

      define_dynamic_methods_for_enumbled_to_models(enumbled_model, prefix: prefix, scope_prefix: scope_prefix)
    rescue NameError
      raise Error, "The model #{class_name} cannot be found.  Uninitialized constant."
    end

    private

    # Define the dynamic methods for this relationship.
    #
    # @todo - we should check for naming conflicts!
    #     dangerous_attribute_method?(method_name)
    #     method_defined_within?(method_name, self, Module)
    def define_dynamic_methods_for_enumbled_to_models(enumbled_model, prefix: false, scope_prefix: nil)
      model_name = enumbled_model.to_s.underscore
      column_name = "#{model_name}_id"

      cmethod = scope_prefix.blank? ? model_name : "#{scope_prefix}_#{model_name}"
      define_singleton_method(cmethod) do |*args|
        where(column_name => enumbled_model.ids_from_enumablable(args))
      end

      enumbled_model.enumbles.each do |enumble|
        method_name = prefix ? "#{model_name}_#{enumble.enum}?" : "#{enumble.enum}?"
        not_method_name = prefix ? "#{model_name}_not_#{enumble.enum}?" : "not_#{enumble.enum}?"
        define_method(method_name) { self[column_name] == enumble.id }
        define_method(not_method_name) { self[column_name] != enumble.id }
      end
    end
  end
end
