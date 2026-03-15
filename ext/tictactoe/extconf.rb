# frozen_string_literal: true

require "mkmf"
require "rb_sys/mkmf"

# create_rust_makefile delegates the entire build to Cargo.
# The argument must match the [lib] name in Cargo.toml.
create_rust_makefile("tictactoe/tictactoe")
