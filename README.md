# tic-tac-toe-magnus-rb 🦀💎

A Tic Tac Toe game engine with a **Rust core** and a clean **Ruby API**,
packaged with **Nix**.

Exists mostly to practice Ruby + Rust gem packaging with Nix.

```
 X │ · │ O
───┼───┼───
 · │ X │ ·
───┼───┼───
 · │ · │ X
```

---

## What's inside

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Game logic | **Rust** | Board state, move validation, win/draw detection, minimax AI |
| Ruby bindings | **Magnus 0.7** | Zero-cost safe Rust ↔ Ruby bridge |
| Gem extension | **rb\_sys + rake-compiler** | Drives `cargo build` from `extconf.rb` |
| Dev shell | **Nix (classical)** | Reproducible Ruby + Rust toolchain, no version drift |
| Gem deps | **bundlerEnv + bundix** | SHA-256-pinned Ruby gems inside the Nix sandbox |

---

## Getting started

### With Nix (recommended)

```sh
git clone https://github.com/kisp/tic-tac-toe-magnus-rb
cd tic-tac-toe-magnus-rb

nix-shell                      # enter the reproducible dev shell
bundle install                 # install Ruby gems
bundix                         # pin gems → gemset.nix  (first time only)
bundle exec rake compile       # build the Rust extension
bundle exec rake test          # run the test suite (98 tests)
```

With [direnv](https://direnv.net) + [nix-direnv](https://github.com/nix-community/nix-direnv):

```sh
direnv allow    # shell activates automatically on every cd into the project
```

### Without Nix

You need Ruby ≥ 3.1 and Rust stable on your `PATH`:

```sh
bundle install
bundle exec rake compile
bundle exec rake test
```

---

## Try it in the REPL

After compiling the extension, start an IRB session with the gem pre-loaded:

```sh
bundle exec rake irb
```

```
irb(main):001> TicTacToe::Game.new
=>
 · │ · │ ·
───┼───┼───
 · │ · │ ·
───┼───┼───
 · │ · │ ·

  Current player : X
  State          : playing
  Valid moves    : 0, 1, 2, 3, 4, 5, 6, 7, 8
irb(main):002> g = TicTacToe::Game.new
=>
 · │ · │ ·
───┼───┼───
 · │ · │ ·
───┼───┼───
 · │ · │ ·

  Current player : X
  State          : playing
  Valid moves    : 0, 1, 2, 3, 4, 5, 6, 7, 8
irb(main):003> g.current_player
=> "x"
irb(main):004> g.valid_moves
=> [0, 1, 2, 3, 4, 5, 6, 7, 8]
irb(main):005> g.make_move 3
=> nil
irb(main):006> g
=>
 · │ · │ ·
───┼───┼───
 X │ · │ ·
───┼───┼───
 · │ · │ ·

  Current player : O
  State          : playing
  Valid moves    : 0, 1, 2, 4, 5, 6, 7, 8
irb(main):007> exit
```

---

## Nix architecture

```
shell.nix / default.nix
│
├── shell.nix                  # `nix-shell`
│   ├── ruby_3_3               # from nixpkgs
│   ├── rustc / cargo          # stable Rust toolchain from nixpkgs
│   ├── bundlerEnv             # all Gemfile gems, SHA-256 locked
│   ├── bundix                 # gems → gemset.nix helper
│   └── shellHook              # sets RUBY_ROOT, RUBYLIB, greets you
│
└── default.nix                # `nix-build`
    └── mkDerivation           # compiles the Rust ext in the sandbox
                               # (requires vendored Cargo deps — see below)
```

### Vendoring Cargo dependencies

The Nix sandbox has no network access, so Cargo crates must be vendored
before `nix-build` can compile the extension.  Three approaches are documented
in [`nix/vendor-cargo-deps.nix`](nix/vendor-cargo-deps.nix):

| Approach | How |
|----------|-----|
| `importCargoLock` | Commit `Cargo.lock`; Nix fetches at eval time (easiest) |
| `fetchCargoTarball` | Explicit SHA-256 hash in `default.nix` |
| Committed vendor dir | `cargo vendor` + `[source.vendored-sources]` (fully offline) |

### Gem pinning with bundix

```
Gemfile  →  bundle install  →  Gemfile.lock  →  bundix  →  gemset.nix
```

Both `Gemfile.lock` and `gemset.nix` are committed — they are the Nix
equivalents of a lockfile.  See [`nix/bundix-workflow.md`](nix/bundix-workflow.md)
for the full update procedure.

---

## Ruby API

```ruby
require "tic_tac_toe_magnus"

g = TicTacToe::Game.new

puts TicTacToe::Game.position_legend
# =>
#   0 │ 1 │ 2
#  ───┼───┼───
#   3 │ 4 │ 5
#  ───┼───┼───
#   6 │ 7 │ 8

g.valid_moves       # => [0,1,2,3,4,5,6,7,8]
g.make_move(4)      # X takes centre
g.current_player    # => "o"
g.state             # => "playing" | "x_wins" | "o_wins" | "draw"
g.best_move         # => Integer (minimax) or nil if game over
puts g              # ASCII board
g.winner            # => :x | :o | nil
g.over?             # => true/false
g.reset             # reuse the same Ruby object
```

`make_move` raises `ArgumentError` on out-of-range positions, occupied cells,
or moves after the game is over.

---

## Project layout

```
tic-tac-toe-magnus-rb/
├── shell.nix                  # Nix dev shell (nix-shell)
├── default.nix                # Nix package derivation (nix-build)
├── .envrc                     # direnv → nix-shell
├── .gitignore
├── nix/
│   ├── vendor-cargo-deps.nix  # how to vendor Cargo crates for nix-build
│   └── bundix-workflow.md     # gem pinning cookbook
│
├── tic_tac_toe_magnus.gemspec
├── Gemfile  /  Gemfile.lock   # committed — Nix lockfile for Ruby deps
├── gemset.nix                 # generated by bundix, also committed
├── Rakefile                   # compile + test tasks
│
├── ext/tictactoe/
│   ├── extconf.rb             # create_rust_makefile(...)
│   ├── Cargo.toml             # cdylib + magnus 0.7
│   └── src/lib.rs             # ALL game logic + Magnus bindings
│
├── lib/
│   ├── tictactoe.rb           # loads .so, adds Ruby sugar
│   └── tictactoe/version.rb
│
├── test/
│   ├── test_helper.rb
│   ├── test_initial_state.rb
│   ├── test_make_move.rb
│   ├── test_win_detection.rb  # all 8 winning lines × 2 players = 16 tests
│   ├── test_draw_detection.rb
│   ├── test_minimax_ai.rb
│   ├── test_rendering.rb
│   ├── test_reset.rb
│   └── test_integration.rb
│
├── bin/console                # IRB session with gem pre-loaded
└── examples/demo.rb           # full feature showcase
```

---

## How the Rust extension works

```
┌─────────────────────────────────────┐
│  Ruby caller                        │
│  TicTacToe::Game.new / make_move …  │
└────────────┬────────────────────────┘
             │  Magnus — safe Rust ↔ Ruby, no GC pressure
┌────────────▼────────────────────────┐
│  Game (magnus::wrap → Mutex<Inner>) │
│  ┌──────────────────────────────┐   │
│  │  GameInner (pure Rust)       │   │
│  │  • board: [Cell; 9]          │   │
│  │  • current_player: Player    │   │
│  │  • valid_moves()             │   │
│  │  • make_move(pos)            │   │
│  │  • state() / check_winner()  │   │
│  │  • minimax() / best_move()   │   │
│  │  • to_ascii()                │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

The `Mutex<GameInner>` wrapper makes the Ruby object safe to share across
Ractor/thread boundaries.

---

## Test suite

```sh
bundle exec rake test
```

98 tests across 8 files — initial state, move mechanics, all 8 winning lines
for both players, draw detection, AI correctness (winning moves, blocking
moves, perfect-play draw), rendering, reset, and integration scenarios
including thread safety.

---

## License

MIT
