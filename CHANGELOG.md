# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-15

### Added
- Initial release.
- Rust core with full Tic Tac Toe game logic: board state, move validation,
  win/draw detection, and unbeatable minimax AI.
- Ruby bindings via Magnus 0.7 (`TicTacToe::Game`).
- `make_move`, `valid_moves`, `current_player`, `state`, `winner`, `over?`,
  `best_move`, `reset`, and `position_legend` API.
- ASCII board rendering via `puts game`.
- 98-test suite covering all 8 winning lines for both players, draw detection,
  AI correctness, rendering, reset, and thread safety.
- Nix dev shell and `nix-build` derivation for reproducible builds.
- `rb_sys` + `rake-compiler` build pipeline.

[0.1.0]: https://github.com/kisp/tic-tac-toe-magnus-rb/releases/tag/v0.1.0
