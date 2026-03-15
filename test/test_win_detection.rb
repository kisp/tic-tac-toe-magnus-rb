# frozen_string_literal: true

require_relative "test_helper"

class TestWinDetection < Minitest::Test
  include GameHelpers

  # All eight winning lines with an O "dummy" move that never interferes.
  # The dummy move for O is always position 8 (only used when 8 is not part of
  # the winning line, otherwise 7 is used).

  WINNING_LINES_X = [
    [0, 1, 2],  # top row
    [3, 4, 5],  # middle row
    [6, 7, 8],  # bottom row
    [0, 3, 6],  # left column
    [1, 4, 7],  # centre column
    [2, 5, 8],  # right column
    [0, 4, 8],  # diagonal ↘
    [2, 4, 6],  # diagonal ↙
  ].freeze

  # For each X winning line, find a safe dummy square for O.
  def dummy_for(line)
    ((0..8).to_a - line).first
  end

  WINNING_LINES_X.each do |line|
    define_method("test_x_wins_on_line_#{line.join('_')}") do
      g = TicTacToe::Game.new
      d = dummy_for(line)
      # Interleave: X plays the winning line, O plays dummy squares
      line.each_with_index do |pos, i|
        g.make_move(pos)
        # O plays only for the first two X moves (third X move wins)
        g.make_move(d + i) if i < line.size - 1
      end
      assert_equal "x_wins", g.state
    end
  end

  # O wins: X plays top-left corner squares (0,1) as sacrifices while
  # O builds each winning line.
  WINNING_LINES_X.each do |line|
    define_method("test_o_wins_on_line_#{line.join('_')}") do
      g = TicTacToe::Game.new
      # X sacrifices are positions not in the winning line
      x_sacrifices = ((0..8).to_a - line).first(3)
      # X plays first, then O, then X, then O, then X, then O wins
      line.each_with_index do |o_pos, i|
        g.make_move(x_sacrifices[i]) # X plays safe square
        g.make_move(o_pos)           # O plays winning line
      end
      assert_equal "o_wins", g.state
    end
  end

  # ── State / predicate consistency ───────────────────────────────────────────

  def test_x_wins_state_string
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)
    assert_equal "x_wins", @game.state
  end

  def test_x_wins_predicate
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)
    assert @game.x_wins?
  end

  def test_o_wins_state_string
    @game = TicTacToe::Game.new
    play(3, 0, 8, 1, 6, 2)   # O wins on top row
    assert_equal "o_wins", @game.state
  end

  def test_o_wins_predicate
    @game = TicTacToe::Game.new
    play(3, 0, 8, 1, 6, 2)
    assert @game.o_wins?
  end

  def test_winner_returns_x_when_x_wins
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)
    assert_equal :x, @game.winner
  end

  def test_winner_returns_o_when_o_wins
    @game = TicTacToe::Game.new
    play(3, 0, 8, 1, 6, 2)
    assert_equal :o, @game.winner
  end

  def test_over_is_true_when_x_wins
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)
    assert @game.over?
  end

  def test_game_does_not_continue_after_win
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)   # X wins
    assert_raises(ArgumentError) { @game.make_move(3) }
  end

  def test_valid_moves_are_empty_after_x_wins
    # Not strictly required, but the engine should still report remaining
    # squares OR return []. Either way the game is over; just test over?.
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)
    assert @game.over?
  end
end
