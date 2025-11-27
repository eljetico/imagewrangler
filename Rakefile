# frozen_string_literal: true

require "rake/testtask"
require "standard/rake"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
