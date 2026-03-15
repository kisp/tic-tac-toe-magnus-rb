# frozen_string_literal: true

require_relative "lib/tictactoe/version"

Gem::Specification.new do |spec|
  spec.name    = "tic_tac_toe_magnus"
  spec.version = TicTacToe::VERSION
  spec.authors = ["Your Name"]
  spec.email   = ["you@example.com"]

  spec.summary = "Tic Tac Toe engine — Rust core, Ruby API via Magnus"
  spec.description = <<~DESC
    A fully-featured Tic Tac Toe engine implemented in Rust with Ruby bindings
    via Magnus (tic-tac-toe-magnus-rb). Supports move validation, win/draw
    detection, ASCII board rendering, and an unbeatable minimax AI opponent.

    Exists mostly to practice Ruby + Rust gem packaging with Nix.
  DESC
  spec.homepage = "https://github.com/example/tic-tac-toe-magnus-rb"
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # All files tracked by git, plus compiled extension
  spec.files = Dir[
    "lib/**/*.rb",
    "ext/**/*.{rb,rs,toml}",
    "*.{md,gemspec}",
    "Gemfile",
    "Rakefile"
  ]

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/tictactoe/extconf.rb"]

  # rb_sys provides the bridge between RubyGems and Cargo
  spec.add_dependency "rb_sys", "~> 0.9"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.2"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.6"
end
