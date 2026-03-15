# frozen_string_literal: true

require_relative "test_helper"

class TestGameInitialState < Minitest::Test
  def setup
    @game = TicTacToe::Game.new
  end

  def test_new_returns_a_game_instance
    assert_instance_of TicTacToe::Game, @game
  end

  def test_initial_state_is_playing
    assert_equal "playing", @game.state
  end

  def test_initial_current_player_is_x
    assert_equal "x", @game.current_player
  end

  def test_initial_valid_moves_contains_all_nine_positions
    assert_equal (0..8).to_a, @game.valid_moves.sort
  end

  def test_initial_valid_moves_count_is_nine
    assert_equal 9, @game.valid_moves.size
  end

  def test_game_is_not_over_at_start
    refute @game.over?
  end

  def test_winner_is_nil_at_start
    assert_nil @game.winner
  end

  def test_draw_is_false_at_start
    refute @game.draw?
  end

  def test_x_wins_is_false_at_start
    refute @game.x_wins?
  end

  def test_o_wins_is_false_at_start
    refute @game.o_wins?
  end

  def test_to_s_contains_dots_for_empty_cells
    board = @game.to_s
    assert_equal 9, board.scan("·").size
  end

  def test_to_s_does_not_contain_any_x_at_start
    refute_match(/X/, @game.to_s)
  end

  def test_to_s_does_not_contain_any_o_at_start
    refute_match(/O/, @game.to_s)
  end
end
