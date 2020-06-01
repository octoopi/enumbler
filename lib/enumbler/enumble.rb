# frozen_string_literal: true

module Enumbler
  # Class that holds each row of Enumble data.
  #
  # @todo We need to support additional options/attributes beyond the id/label
  #   pairs.  Is on the backburner for a moment.
  class Enumble
    attr_reader :id, :enum, :label, :label_column_name, :options

    def initialize(enum, id, label: nil, label_column_name: :label, **options)
      @id = id
      @enum = enum
      @label = label || enum.to_s.dasherize
      @label_column_name = label_column_name
      @options = options
    end

    def ==(other)
      other.class == self.class &&
        (other.id == id || other.enum == enum || other.label == label)
    end

    def attributes
      {
        id: id,
        label_column_name => label,
      }
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
  end
end
