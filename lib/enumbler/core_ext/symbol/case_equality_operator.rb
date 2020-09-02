# frozen_string_literal: true

# Use case equality operator with an enabled class.
#
#   case House.black
#   when :black
#     'this is true'
#   when :blue, :purple
#     'this is not'
#   end
class Symbol
  def ===(other)
    super ||
      other.class.included_modules.include?(Enumbler::Enabler) &&
        other.enumble.enum == self

  # Calling #enumble on a new instance that has not been defined raises an
  # error, so catching that edge case here
  rescue Enumbler::Error
    false
  end
end
