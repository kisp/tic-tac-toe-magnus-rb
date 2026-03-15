# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rb_sys/extensiontask"

GEMSPEC = Gem::Specification.load("tic_tac_toe_magnus.gemspec")

RbSys::ExtensionTask.new("tictactoe", GEMSPEC) do |ext|
  ext.lib_dir = "lib/tictactoe"
end

Rake::TestTask.new(:test) do |t|
  t.libs    << "lib" << "test"
  t.pattern = "test/test_*.rb"
  t.verbose = true
  t.warning = true
end

# Tests depend on the extension being compiled first
task test: :compile

task default: :test
