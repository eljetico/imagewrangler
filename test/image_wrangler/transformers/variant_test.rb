# frozen_string_literal: true
# frozen_string_literal: true

require_relative '../../test_helper'

class ImageWrangler::Transformers::VariantTest < Minitest::Test
  def setup
    @variant = ImageWrangler::Transformers::Variant
  end

  def test_base_class_instantiation
    subject = @variant.new

    assert subject.errors.is_a?(ImageWrangler::Errors)

    assert_raises NotImplementedError do
      subject.validate!
    end

    assert_raises NotImplementedError do
      subject.process
    end
  end

  def test_filename_when_supplied
    subject = @variant.new({
      filename: 'something.jpg'
    })

    assert_equal('something.jpg', subject.filename)
  end

  def test_filename_from_supplied_filepath
    subject = @variant.new({
      filepath: '/path/to/something.jpg'
    })

    assert_equal('something.jpg', subject.filename)
  end

  def test_filename_when_none_supplied
    subject = @variant.new
    assert_match(/\Aimage_wrangler\.\w{6,}/, subject.filename)
  end
end
