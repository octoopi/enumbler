# frozen_string_literal: true

module Enumbler
  # Not sure if this will be needed but was leaning toward a custom wrapper for
  # our array holding the `enumbles` for our model.  As it is, allows you to
  # query them based on the enum:
  #
  # ```
  # Color.enumbles.black # => [Enumbler::Enumble]
  # ```
  class Collection < Array
    def method_missing(method_name, *args, &block)
      enumble = find { |e| e.enum == method_name }
      return enumble if enumble.present?

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      enumble = find { |e| e.enum == method_name }
      enumble.present? || super
    end
  end
end
