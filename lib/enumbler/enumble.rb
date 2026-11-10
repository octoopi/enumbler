# frozen_string_literal: true

module Enumbler
  # Class that holds each row of Enumble data.
  class Enumble
    attr_reader :id, :enum, :label, :label_column_name

    # @param allow_duplicate_labels [Boolean] when true, a shared label no
    #   longer makes two Enumbles equal; only id or enum do.  Set by
    #   {Enumbler::Enabler::ClassMethods#enumbler_allow_duplicate_labels}.
    def initialize(enum, id, label: nil, label_column_name: :label, allow_duplicate_labels: false, **attributes)
      @id = id
      @enum = enum
      @label_column_name = label_column_name
      @allow_duplicate_labels = allow_duplicate_labels
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

    def eql?(other)
      other.class == self.class &&
        (other.id == id || other.enum == enum || same_label_as?(other))
    end

    # Whether this Enumble may share its label with another in its model.
    # @return [Boolean]
    def allow_duplicate_labels?
      @allow_duplicate_labels
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
