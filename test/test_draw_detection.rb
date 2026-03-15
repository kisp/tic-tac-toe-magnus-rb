# frozen_string_literal: true

require_relative "test_helper"

class TestDrawDetection < Minitest::Test
  include GameHelpers

  # Known draw sequence (no winning line formed):
  #   X │ O │ X
  #  ───┼───┼───
  #   X │ X │ O
  #  ───┼───┼───
  #   O │ X │ O
  DRAW_SEQUENCE = [0, 1, 2, 5, 3, 6, 4, 8, 7].freeze

  def setup
    @game = TicTacToe::Game.new
    DRAW_SEQUENCE.each { |m| @game.make_move(m) }
  end

  def test_state_is_draw
    assert_equal "draw", @game.state
  end

  def test_draw_predicate_is_true
    assert @game.draw?
  end

  def test_over_is_true_on_draw
    assert @game.over?
  end

  def test_winner_is_nil_on_draw
    assert_nil @game.winner
  end

  def test_x_wins_is_false_on_draw
    refute @game.x_wins?
  end

  def test_o_wins_is_false_on_draw
    refute @game.o_wins?
  end

  def test_no_dots_remaining_on_full_board
    refute_match(/·/, @game.to_s)
  end

  def test_board_has_nine_marks_on_draw
    marks = @game.to_s.scan(/[XO]/).size
    assert_equal 9, marks
  end

  def test_valid_moves_is_empty_on_draw
    assert_empty @game.valid_moves
  end

  def test_make_move_raises_on_drawn_game
    assert_raises(ArgumentError) { @game.make_move(0) }
  end

  def test_second_known_draw_sequence
    g = TicTacToe::Game.new
    # Another full-board draw:
    #   O │ X │ O
    #  ───┼───┼───
    #   X │ X │ O
    #  ───┼───┼───
    #   X │ O │ X
    [4, 0, 6, 2, 3, 5, 8, 7, 1].each { |m| g.make_move(m) }
    assert_equal "draw", g.state
  end
end
