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

desc "Launch IRB with the gem loaded and ready to use"
task irb: :compile do
  exec "irb -I lib -r tictactoe"
end

# ---------------------------------------------------------------------------
# Release helpers
# ---------------------------------------------------------------------------

def current_version
  require_relative "lib/tictactoe/version"
  TicTacToe::VERSION
end

def bump_version(version, type)
  major, minor, patch = version.split(".").map(&:to_i)
  case type.to_sym
  when :major then "#{major + 1}.0.0"
  when :minor then "#{major}.#{minor + 1}.0"
  when :patch then "#{major}.#{minor}.#{patch + 1}"
  else raise ArgumentError, "Unknown bump type '#{type}'. Use major, minor, or patch."
  end
end

desc <<~DESC
  Bump version, commit, tag, build gem, and print the push command.

  Usage:
    bundle exec rake release            # default: patch bump
    bundle exec rake release[minor]
    bundle exec rake release[major]
DESC
task :release, [:type] do |_, args|
  type       = args[:type] || "patch"
  old_version = current_version
  new_version = bump_version(old_version, type)

  version_file = "lib/tictactoe/version.rb"
  content = File.read(version_file)
  updated = content.sub(/VERSION\s*=\s*"[^"]+"/, %(VERSION = "#{new_version}"))
  if content == updated
    raise "VERSION constant not found in #{version_file} — cannot update version"
  end

  File.write(version_file, updated)
  puts "Bumped #{old_version} → #{new_version}"

  sh "bundle lock"
  sh "git add #{version_file}"
  sh "git add Gemfile.lock"
  sh %(git commit -m "Bump version to #{new_version}")
  sh %(git tag -a "v#{new_version}" -m "Release v#{new_version}")

  gemspec_file = File.basename(GEMSPEC.loaded_from)
  sh "gem build #{gemspec_file}"

  gem_file = "#{GEMSPEC.name}-#{new_version}.gem"
  puts
  puts "Gem built: #{gem_file}"
  puts
  puts "Push to RubyGems with:"
  puts
  puts "  gem push #{gem_file}"
  puts
end
