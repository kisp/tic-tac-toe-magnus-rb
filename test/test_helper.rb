# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"

# Optional: pretty reporter when running locally
begin
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
rescue LoadError
  # minitest-reporters not installed — plain output is fine
end

require "tictactoe"

module GameHelpers
  # Play a sequence of moves without caring who's turn it is.
  def play(*moves)
    moves.each { |m| @game.make_move(m) }
  end

  # Build a board from a symbol sequence where :x/:o/:_ map to marks.
  #   build_board(:x, :o, :_, :_, :x, :_, :_, :_, :o)
  # The sequence is applied alternating X then O, matching the actual
  # turn order encoded in the list itself.
  def build_board(*marks)
    g = TicTacToe::Game.new
    # Replay moves in the order they appear so the turn counter stays correct.
    x_moves = []
    o_moves = []
    marks.each_with_index do |m, i|
      case m
      when :x then x_moves << i
      when :o then o_moves << i
      end
    end
    # Interleave: X always goes first per game rules.
    x_moves.zip(o_moves).each do |x, o|
      g.make_move(x) if x
      g.make_move(o) if o
    end
    g
  end
end
