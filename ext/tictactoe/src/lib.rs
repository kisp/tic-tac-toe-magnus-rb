// ext/tictactoe/src/lib.rs
//
// Full Tic Tac Toe engine exposed to Ruby via Magnus.
//
// Board layout (positions 0-8):
//
//   0 │ 1 │ 2
//  ───┼───┼───
//   3 │ 4 │ 5
//  ───┼───┼───
//   6 │ 7 │ 8

use magnus::{
    define_module, exception, function, method,
    prelude::*,
    Error, Ruby,
};
use std::sync::Mutex;

// ─── Domain types ────────────────────────────────────────────────────────────

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Cell {
    Empty,
    X,
    O,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Player {
    X,
    O,
}

impl Player {
    fn cell(self) -> Cell {
        match self {
            Player::X => Cell::X,
            Player::O => Cell::O,
        }
    }

    fn opponent(self) -> Player {
        match self {
            Player::X => Player::O,
            Player::O => Player::X,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum GameState {
    Playing,
    XWins,
    OWins,
    Draw,
}

// ─── Core engine ─────────────────────────────────────────────────────────────

/// Winning line combinations (indices into the 9-cell board array).
const WINNING_LINES: [[usize; 3]; 8] = [
    [0, 1, 2], // top row
    [3, 4, 5], // middle row
    [6, 7, 8], // bottom row
    [0, 3, 6], // left column
    [1, 4, 7], // centre column
    [2, 5, 8], // right column
    [0, 4, 8], // diagonal ↘
    [2, 4, 6], // diagonal ↙
];

#[derive(Clone, Debug)]
struct GameInner {
    board: [Cell; 9],
    current_player: Player,
}

impl GameInner {
    fn new() -> Self {
        GameInner {
            board: [Cell::Empty; 9],
            current_player: Player::X,
        }
    }

    // ── Queries ───────────────────────────────────────────────────────────────

    fn valid_moves(&self) -> Vec<usize> {
        self.board
            .iter()
            .enumerate()
            .filter_map(|(i, &c)| if c == Cell::Empty { Some(i) } else { None })
            .collect()
    }

    fn check_winner(&self) -> Option<Player> {
        for &[a, b, c] in &WINNING_LINES {
            let ca = self.board[a];
            if ca != Cell::Empty && ca == self.board[b] && ca == self.board[c] {
                return Some(match ca {
                    Cell::X => Player::X,
                    Cell::O => Player::O,
                    Cell::Empty => unreachable!(),
                });
            }
        }
        None
    }

    fn state(&self) -> GameState {
        match self.check_winner() {
            Some(Player::X) => GameState::XWins,
            Some(Player::O) => GameState::OWins,
            None if self.valid_moves().is_empty() => GameState::Draw,
            None => GameState::Playing,
        }
    }

    // ── Mutation ──────────────────────────────────────────────────────────────

    fn make_move(&mut self, pos: usize) -> Result<(), String> {
        if pos > 8 {
            return Err(format!(
                "Position {} is out of range — valid positions are 0..8",
                pos
            ));
        }
        if self.board[pos] != Cell::Empty {
            return Err(format!(
                "Position {} is already occupied",
                pos
            ));
        }
        if self.state() != GameState::Playing {
            return Err("The game is already over".to_string());
        }
        self.board[pos] = self.current_player.cell();
        self.current_player = self.current_player.opponent();
        Ok(())
    }

    // ── Minimax AI ────────────────────────────────────────────────────────────
    //
    // Classic negamax formulation: the score is always from the perspective of
    // `maximising_player` (the side that asked for a move).
    //
    // Returns a score in [-10, 10]:
    //   +10  ⟹  maximising_player wins
    //   -10  ⟹  maximising_player loses
    //     0  ⟹  draw
    //
    // The depth penalty makes the engine prefer faster wins and slower losses,
    // which produces more natural-looking play.

    fn minimax(&self, maximising_player: Player, depth: i32, is_max: bool) -> i32 {
        match self.state() {
            GameState::XWins => {
                let winner_is_max = maximising_player == Player::X;
                let base = if winner_is_max { 10 } else { -10 };
                base - depth * base.signum()
            }
            GameState::OWins => {
                let winner_is_max = maximising_player == Player::O;
                let base = if winner_is_max { 10 } else { -10 };
                base - depth * base.signum()
            }
            GameState::Draw => 0,
            GameState::Playing => {
                let moves = self.valid_moves();
                if is_max {
                    let mut best = i32::MIN;
                    for m in moves {
                        let mut next = self.clone();
                        next.make_move(m).unwrap();
                        best = best.max(next.minimax(maximising_player, depth + 1, false));
                    }
                    best
                } else {
                    let mut best = i32::MAX;
                    for m in moves {
                        let mut next = self.clone();
                        next.make_move(m).unwrap();
                        best = best.min(next.minimax(maximising_player, depth + 1, true));
                    }
                    best
                }
            }
        }
    }

    /// Returns the best position for the current player or `None` if the game
    /// is already over.
    fn best_move(&self) -> Option<usize> {
        if self.state() != GameState::Playing {
            return None;
        }
        let moves = self.valid_moves();
        let player = self.current_player;

        let mut best_score = i32::MIN;
        let mut best_pos = moves[0];

        for m in moves {
            let mut next = self.clone();
            next.make_move(m).unwrap();
            // After we play `m` it's the opponent's turn → is_max = false.
            let score = next.minimax(player, 0, false);
            if score > best_score {
                best_score = score;
                best_pos = m;
            }
        }
        Some(best_pos)
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    fn to_ascii(&self) -> String {
        let s = |c: Cell| match c {
            Cell::X => " X ",
            Cell::O => " O ",
            Cell::Empty => " · ",
        };
        let b = &self.board;
        format!(
            "{}│{}│{}\n───┼───┼───\n{}│{}│{}\n───┼───┼───\n{}│{}│{}",
            s(b[0]), s(b[1]), s(b[2]),
            s(b[3]), s(b[4]), s(b[5]),
            s(b[6]), s(b[7]), s(b[8]),
        )
    }
}

// ─── Magnus Ruby wrapper ──────────────────────────────────────────────────────
//
// `#[magnus::wrap]` generates the glue that lets Ruby's GC manage the struct.
// `free_immediately` means the destructor runs as soon as the Ruby object is
// collected — safe here because GameInner holds no Ruby values.

#[magnus::wrap(class = "TicTacToe::Game", free_immediately, size)]
struct Game(Mutex<GameInner>);

impl Game {
    // ── Constructor ───────────────────────────────────────────────────────────

    fn new() -> Self {
        Game(Mutex::new(GameInner::new()))
    }

    // ── Ruby-callable methods ─────────────────────────────────────────────────

    /// Returns an Array of Integer positions that are currently unoccupied.
    fn valid_moves(&self) -> Vec<usize> {
        self.0.lock().unwrap().valid_moves()
    }

    /// Place the current player's mark at `pos` (0-8).
    /// Raises ArgumentError on invalid or already-taken positions.
    fn make_move(&self, pos: usize) -> Result<(), Error> {
        self.0
            .lock()
            .unwrap()
            .make_move(pos)
            .map_err(|msg| Error::new(exception::arg_error(), msg))
    }

    /// Returns one of: "playing", "x_wins", "o_wins", "draw".
    fn state(&self) -> &'static str {
        match self.0.lock().unwrap().state() {
            GameState::Playing => "playing",
            GameState::XWins => "x_wins",
            GameState::OWins => "o_wins",
            GameState::Draw => "draw",
        }
    }

    /// Returns "x" or "o" — the player whose turn it is.
    fn current_player(&self) -> &'static str {
        match self.0.lock().unwrap().current_player {
            Player::X => "x",
            Player::O => "o",
        }
    }

    /// Returns the best move for the current player (minimax), or nil when the
    /// game is over.
    fn best_move(&self) -> Option<usize> {
        self.0.lock().unwrap().best_move()
    }

    /// Returns the ASCII-art board as a String (used by Ruby's `puts`).
    fn to_s(&self) -> String {
        self.0.lock().unwrap().to_ascii()
    }

    /// Resets the board to the initial state (X goes first).
    fn reset(&self) {
        *self.0.lock().unwrap() = GameInner::new();
    }
}

// ─── Extension entry point ────────────────────────────────────────────────────

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    // Ensure the TicTacToe namespace exists (it may already be defined in
    // lib/tictactoe.rb; define_module is idempotent).
    let m = ruby.define_module("TicTacToe")?;

    let c = m.define_class("Game", ruby.class_object())?;

    // Constructor — called as TicTacToe::Game.new
    c.define_singleton_method("new", function!(Game::new, 0))?;

    // Board query methods
    c.define_method("valid_moves",    method!(Game::valid_moves,    0))?;
    c.define_method("state",          method!(Game::state,          0))?;
    c.define_method("current_player", method!(Game::current_player, 0))?;

    // Mutation
    c.define_method("make_move",      method!(Game::make_move,      1))?;
    c.define_method("reset",          method!(Game::reset,          0))?;

    // AI
    c.define_method("best_move",      method!(Game::best_move,      0))?;

    // Rendering
    c.define_method("to_s",           method!(Game::to_s,           0))?;

    Ok(())
}
