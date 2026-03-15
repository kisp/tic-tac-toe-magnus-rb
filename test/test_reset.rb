# frozen_string_literal: true

require_relative "test_helper"

class TestReset < Minitest::Test
  include GameHelpers

  def setup
    @game = TicTacToe::Game.new
  end

  def test_reset_clears_the_board
    play(0, 1, 2)
    @game.reset
    assert_equal 9, @game.valid_moves.size
  end

  def test_reset_returns_state_to_playing
    play(0, 6, 1, 7, 2)         # X wins
    @game.reset
    assert_equal "playing", @game.state
  end

  def test_reset_sets_current_player_back_to_x
    play(0)                      # X plays, leaving it O's turn
    @game.reset
    assert_equal "x", @game.current_player
  end

  def test_reset_allows_moves_after_win
    play(0, 6, 1, 7, 2)         # X wins — game over
    @game.reset
    @game.make_move(4)           # should not raise
  end

  def test_reset_allows_moves_after_draw
    [0, 1, 2, 5, 3, 6, 4, 8, 7].each { |m| @game.make_move(m) }
    @game.reset
    @game.make_move(0)           # should not raise
  end

  def test_reset_restores_all_nine_valid_moves
    play(0, 1, 2, 3, 4)
    @game.reset
    assert_equal (0..8).to_a, @game.valid_moves.sort
  end

  def test_reset_clears_marks_from_to_s
    play(0, 1, 2)
    @game.reset
    refute_match(/[XO]/, @game.to_s)
    assert_equal 9, @game.to_s.scan("·").size
  end

  def test_same_object_identity_after_reset
    original_object_id = @game.object_id
    @game.reset
    assert_equal original_object_id, @game.object_id
  end

  def test_multiple_resets_in_sequence
    3.times do
      play(0, 1, 2, 5, 3, 6, 4, 8, 7)  # draw sequence – fills all 9 squares
      @game.reset
      assert_equal "playing", @game.state
      assert_equal 9, @game.valid_moves.size
    end
  end
end
