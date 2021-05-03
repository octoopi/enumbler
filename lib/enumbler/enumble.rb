# frozen_string_literal: true

module Enumbler
  # Class that holds each row of Enumble data.
  class Enumble
    attr_reader :id, :enum, :label, :label_column_name

    def initialize(enum, id, label: nil, label_column_name: :label, **attributes)
      @id = id
      @enum = enum
      @label_column_name = label_column_name
      @label = (label_col_specified? ? attributes[label_column_name] : label) || enum.to_s.dasherize
      @additional_attributes = attributes || {}
      @additional_attributes.merge!({ label: label }) unless label.nil?
    end

    def ==(other)
      other.class == self.class &&
        (other.id == id || other.enum == enum || other.label == label)
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
        (other.id == id || other.enum == enum || other.label == label)
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

    def label_col_specified?
      label_column_name != :label
    end
  end
end
