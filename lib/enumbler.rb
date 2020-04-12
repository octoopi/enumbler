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
    # @param **options [Hash] additional options passed to `belongs_to`
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

    private

    def define_dynamic_methods_for_enumbled_to_models(prefix: nil)
      model_name = @enumbled_model.to_s.underscore

      method = if prefix.blank?
                 model_name
               else
                 "#{prefix}_#{model_name}"
               end

      define_singleton_method(method) do |*args|
        where("#{model_name}_id": @enumbled_model.ids_from_enumablable(args))
      end
    end
  end
end
