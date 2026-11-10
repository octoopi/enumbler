# frozen_string_literal: true

module Enumbler
  # Class that holds each row of Enumble data.
  class Enumble
    attr_reader :id, :enum, :label, :label_column_name

    def initialize(enum, id, label: nil, label_column_name: :label, **attributes)
      @id = id
      @enum = enum
      @label_column_name = label_column_name
      @allow_duplicate_labels = false
      @label = (label_col_specified? ? attributes[label_column_name] : label) || enum.to_s.dasherize
      @additional_attributes = attributes || {}
      @additional_attributes.merge!({ label: label }) unless label.nil?
    end

    # Equal when the id or enum match, or the label matches and neither side
    # allows duplicate labels.
    def ==(other)
      other.class == self.class &&
        (other.id == id || other.enum == enum || same_label_as?(other))
    end

    def attributes
      hash = { id: id, label_column_name => label }
      @additional_attributes.merge(hash)
    end

    # Used to return itself from a class method.
    #
    # ```
    # Color.black(:enumble) #=> <Enumble:0x00007fb4396a78c8>
    # ```
    # @return [Enumbler::Enumble]
    def enumble
      self
    end

    alias eql? ==

    # Whether this Enumble may share its label with another in its model.
    # @return [Boolean]
    def allow_duplicate_labels?
      @allow_duplicate_labels
    end

    # Lets this Enumble share its label: a shared label no longer makes two
    # Enumbles equal, only id or enum do.  Called by `enumble` on a model that
    # uses {Enumbler::Enabler::ClassMethods#enumbler_allow_duplicate_labels};
    # it is not a constructor keyword so it cannot collide with a column name
    # passed through `**attributes`.
    # @api private
    # @return [self]
    def allow_duplicate_labels!
      @allow_duplicate_labels = true
      self
    end

    # Standardizing the enum for a GraphQL schema with an uppercase string
    # value.
    # @return [String]
    def graphql_enum
      enum.to_s.upcase
    end

    def to_s
      enum
    end

    private

    def same_label_as?(other)
      return false if allow_duplicate_labels? || other.allow_duplicate_labels?

      other.label == label
    end

    def label_col_specified?
      label_column_name != :label
    end
  end
end
