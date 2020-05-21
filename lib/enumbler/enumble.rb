# frozen_string_literal: true

module Enumbler
  # Class that holds each row of Enumble data.
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
  end
end
