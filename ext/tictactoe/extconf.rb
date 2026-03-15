# frozen_string_literal: true

# Suppress "already initialized constant" warnings that arise from the
# Bundler/RubyGems version mismatch present in Ruby 3.3.x.
$VERBOSE = nil

require "mkmf"
require "rb_sys/mkmf"

# create_rust_makefile delegates the entire build to Cargo.
# The argument must match the [lib] name in Cargo.toml.
create_rust_makefile("tictactoe/tictactoe")
