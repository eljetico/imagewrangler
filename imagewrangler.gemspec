# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'image_wrangler/version'

Gem::Specification.new do |s|
  s.license     = 'MIT'
  s.name        = 'imagewrangler'
  s.version     = ImageWrangler.version
  s.date        = '2016-11-22'
  s.summary     = 'Image analyzer and transformer'
  s.description = 'Fault-tolerant tools for handling of image files'
  s.requirements << 'You must have ImageMagick or GraphicsMagick installed'
  s.authors     = ['Tim Davies']
  s.email       = 'eljetico+imagewrangler@gmail.com'
  s.files       = Dir['README.md', 'Rakefile', 'lib/**/*', 'resources/**/*']
  s.required_ruby_version = '>= 2.3.0'

  s.add_dependency 'mini_magick'

  s.add_development_dependency 'webmock'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-minitest'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'rb-readline'
  s.add_development_dependency 'rubocop'
end
