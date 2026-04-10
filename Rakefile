# frozen_string_literal: true

require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:server) do |t|
    t.libs << "lib" << "test"
    t.test_files = FileList['test/server/**/*_test.rb']
  end

  Rake::TestTask.new(:client) do |t|
    t.libs << "lib" << "test"
    t.test_files = FileList['test/client/**/*_test.rb']
  end

  Rake::TestTask.new(:protocol) do |t|
    t.libs << "lib" << "test"
    t.test_files = FileList['test/protocol/**/*_test.rb']
  end
end
