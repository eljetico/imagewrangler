# frozen_string_literal: true

module ImageWrangler
  class Error < StandardError; end

  class MissingImageError < Error; end

  class CorruptImageError < Error; end

  class RemoteImageError < Error; end

  # A simple modified hash-like object similar to ActiveModel::Errors
  class Errors
    include Enumerable

    def initialize
      @errors = Hash.new {|hash, key| hash[key] = []}
    end

    def [](attribute)
      errors[attribute.to_sym]
    end

    # Adds message to error messages keyed by attribute
    # More than one error can be added to attribute
    #
    # If message is a proc, will be called and the result
    # added as a message string
    def add(attribute, message = 'invalid')
      message = message.call if message.respond_to?(:call)

      add_error(attribute.to_sym, message)
    end

    def clear
      errors.clear
    end

    def delete(attribute)
      errors.delete(attribute.to_sym)
    end

    def each
      errors.each_key do |attribute|
        errors[attribute].each { |error| yield attribute, error }
      end
    end

    def empty?
      size.zero?
    end
    alias :blank? :empty?

    def errors
      @errors
    end

    def full_messages
      map { |attribute, message| full_message(attribute, message) }
    end

    def include?(attribute)
      attribute = attribute.to_sym
      errors.key?(attribute) && !errors[attribute].empty?
    end
    alias :has_key? :include?
    alias :key? :include?

    def messages
      errors.inspect
    end

    def size
      values.flatten.size
    end

    def values
      errors.select do |key, value|
        !value.empty?
      end.values
    end

    private

    def add_error(attribute, message)
      unless errors[attribute].include?(message)
        errors[attribute].push(message)
      end
    end

    def full_message(attribute, message)
      return message if attribute == :base
      "#{attribute} #{message}"
    end
  end
end
