# frozen_string_literal: true

module Enumbler
  # Class that holds each row of Enumble data.
  class Enumble
    attr_reader :id, :enum, :label, :options

    def initialize(enum, id, label: nil, **options)
      @id = id
      @enum = enum
      @label = label || enum.to_s.dasherize
      @options = options
    end

    def ==(other)
      other.class == self.class &&
        (other.id == id || other.enum == enum || other.label == label)
    end

    def attributes
      {
        id: id,
        label: label,
      }
    end

    def eql?(other)
      other.class == self.class &&
        (other.id == id || other.enum == enum || other.label == label)
    end
  end
end
