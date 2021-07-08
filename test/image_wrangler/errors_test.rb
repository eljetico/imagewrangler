# frozen_string_literal: true

require_relative "../test_helper"

class ErrorsTest < Minitest::Test
  class Testable
    attr_accessor :errors

    def initialize
      @errors = ImageWrangler::Errors.new
    end
  end

  def setup
    @subject = ImageWrangler::Errors.new
  end

  def test_add
    @subject.add(:foo, "omg")
    refute_empty @subject[:foo]
  end

  def test_delete
    @subject[:foo] << "omg"
    @subject.delete("foo")
    assert_empty @subject[:foo]
  end

  def test_clear
    @subject[:foo] << "omg"
    assert_equal 1, @subject.errors.count

    @subject.clear
    assert_empty @subject.errors
  end

  def test_empty_blank_include
    object = Testable.new
    object.errors[:foo]
    assert_empty object.errors
    assert_predicate object.errors, :blank?
    refute_includes object.errors, :foo
  end

  def test_with_proc
    message = proc { "cannot be CMYK" }
    @subject.add(:topic, message)
    assert_equal @subject[:topic], [message.call]
  end

  def test_testable_object
    object = Testable.new
    object.errors.add(:topic, "must be valid")

    assert object.errors.any?
  end

  def test_to_s
    object = Testable.new
    object.errors.add(:topic, "must be valid")
    object.errors.add(:new_topic, "is missing")
    assert_equal "new_topic is missing; topic must be valid", object.errors.to_s
  end
end
