#!/usr/bin/env ruby
# frozen_string_literal: true
#
# examples/demo.rb
#
# Demonstrates every feature of the TicTacToe gem.
# Run with:  bundle exec ruby examples/demo.rb

require "bundler/setup"
require "tictactoe"

SEP = ("─" * 42).freeze

def header(title)
  puts "\n#{SEP}"
  puts "  #{title}"
  puts SEP
end

# ─── 1. Position reference ───────────────────────────────────────────────────
header("Board position reference")
puts TicTacToe::Game.position_legend

# ─── 2. Basic gameplay API ───────────────────────────────────────────────────
header("Basic gameplay — X wins diagonally")

g = TicTacToe::Game.new

puts "Fresh board:"
puts g
puts
puts "State          : #{g.state}"
puts "Current player : #{g.current_player.upcase}"
puts "Valid moves    : #{g.valid_moves.inspect}"

# Play a quick game where X wins along the main diagonal (0, 4, 8)
[[0, :X], [1, :O], [4, :X], [2, :O], [8, :X]].each do |pos, _mark|
  g.make_move(pos)
end

puts
puts "After moves 0→X, 1→O, 4→X, 2→O, 8→X:"
puts g
puts
puts "State  : #{g.state}"   # => "x_wins"
puts "Winner : #{g.winner}"  # => :x
puts "Over?  : #{g.over?}"

# ─── 3. Draw scenario ────────────────────────────────────────────────────────
header("Draw scenario")

d = TicTacToe::Game.new
# X O X
# X X O
# O X O  — no winner, board full
[0, 1, 2, 5, 3, 6, 4, 8, 7].each { |p| d.make_move(p) }
puts d
puts
puts "State : #{d.state}"   # => "draw"
puts "Draw? : #{d.draw?}"

# ─── 4. Error handling ───────────────────────────────────────────────────────
header("Error handling — occupied cell & out-of-range")

e = TicTacToe::Game.new
e.make_move(4)

begin
  e.make_move(4)   # already taken
rescue ArgumentError => ex
  puts "Occupied cell  → ArgumentError: #{ex.message}"
end

begin
  e.make_move(99)  # out of range
rescue ArgumentError => ex
  puts "Out of range   → ArgumentError: #{ex.message}"
end

# ─── 5. inspect helper ───────────────────────────────────────────────────────
header("Game#inspect — overview at a glance")

i = TicTacToe::Game.new
i.make_move(0)
i.make_move(8)
puts i.inspect

# ─── 6. Minimax AI — single best move ────────────────────────────────────────
header("Minimax AI — ask for a single best move")

ai = TicTacToe::Game.new

puts "Empty board — best move for X:"
puts "  AI recommends position #{ai.best_move}   (centre is optimal)"

# Give O a winning threat on the bottom row (6,7) and let X block
ai.make_move(4)  # X takes centre
ai.make_move(6)  # O takes bottom-left
ai.make_move(0)  # X takes top-left
ai.make_move(7)  # O threatens bottom row (6,7)

puts
puts "Board:"
puts ai
puts
bm = ai.best_move
puts "AI recommends position #{bm} for X — blocks O's winning move at 8"
ai.make_move(bm)
puts
puts "After AI plays #{bm}:"
puts ai

# ─── 7. Full AI vs AI game ───────────────────────────────────────────────────
header("Full AI vs AI game (perfect play → always a draw)")

auto = TicTacToe::Game.new
move_num = 0

until auto.over?
  move_num += 1
  pos = auto.best_move
  player = auto.current_player.upcase
  auto.make_move(pos)
  puts "Move #{move_num}: #{player} → position #{pos}"
end

puts
puts "Final board:"
puts auto
puts
puts "Result: #{auto.state}"   # should be "draw" — perfect play never loses

# ─── 8. Interactive human vs AI helper ───────────────────────────────────────
header("Interactive Human (X) vs AI (O) — skeleton")

puts <<~RUBY
  # Copy this snippet into your own script or irb session:

  require "tictactoe"
  g = TicTacToe::Game.new
  puts TicTacToe::Game.position_legend

  until g.over?
    puts g
    if g.current_player == "x"
      print "Your move (0-8): "
      g.make_move(gets.chomp.to_i)
    else
      ai_pos = g.best_move
      puts "AI plays \#{ai_pos}"
      g.make_move(ai_pos)
    end
  end

  puts g
  puts g.winner ? "\#{g.winner.upcase} wins!" : "It's a draw!"
RUBY

puts "\n#{SEP}"
puts "  Demo complete — all features exercised!"
puts SEP
