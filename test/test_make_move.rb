# frozen_string_literal: true

require_relative "test_helper"

class TestMakeMove < Minitest::Test
  include GameHelpers

  def setup
    @game = TicTacToe::Game.new
  end

  # ── Turn alternation ────────────────────────────────────────────────────────

  def test_first_move_belongs_to_x
    assert_equal "x", @game.current_player
  end

  def test_after_one_move_current_player_is_o
    @game.make_move(0)
    assert_equal "o", @game.current_player
  end

  def test_after_two_moves_current_player_is_x_again
    @game.make_move(0)
    @game.make_move(1)
    assert_equal "x", @game.current_player
  end

  def test_players_alternate_for_all_nine_moves
    expected = %w[x o x o x o x o x]
    moves    = [0, 1, 2, 5, 3, 6, 4, 8, 7]  # draw sequence – no early win
    expected.zip(moves).each_with_index do |(player, pos), i|
      assert_equal player, @game.current_player,
        "Expected #{player} at move #{i + 1}"
      @game.make_move(pos)
    end
  end

  # ── Valid-moves shrinking ────────────────────────────────────────────────────

  def test_valid_moves_shrinks_by_one_after_each_move
    moves = [0, 1, 2, 5, 3, 6, 4, 8, 7]  # draw sequence – no early win
    9.times do |i|
      assert_equal 9 - i, @game.valid_moves.size
      @game.make_move(moves[i])
    end
  end

  def test_played_position_disappears_from_valid_moves
    @game.make_move(4)
    refute_includes @game.valid_moves, 4
  end

  def test_unplayed_positions_remain_in_valid_moves
    @game.make_move(4)
    (0..8).to_a.tap { |a| a.delete(4) }.each do |pos|
      assert_includes @game.valid_moves, pos
    end
  end

  # ── Board reflected in to_s ──────────────────────────────────────────────────

  def test_to_s_shows_x_after_x_plays
    @game.make_move(0)
    assert_match(/X/, @game.to_s)
  end

  def test_to_s_shows_o_after_o_plays
    @game.make_move(0)
    @game.make_move(8)
    assert_equal 2, @game.to_s.scan(/[XO]/).size
  end

  def test_empty_cells_decrease_in_to_s_as_moves_are_made
    @game.make_move(0)
    assert_equal 8, @game.to_s.scan("·").size
  end

  # ── Error cases ─────────────────────────────────────────────────────────────

  def test_raises_on_position_below_range
    # Ruby integers can be negative; underlying is usize so -1 will wrap or error
    # Magnus converts negative to large usize or raises — either is acceptable
    assert_raises(ArgumentError, RangeError, TypeError) { @game.make_move(-1) }
  end

  def test_raises_on_position_9
    err = assert_raises(ArgumentError) { @game.make_move(9) }
    assert_match(/out of range|position/i, err.message)
  end

  def test_raises_on_position_99
    assert_raises(ArgumentError) { @game.make_move(99) }
  end

  def test_raises_on_occupied_cell
    @game.make_move(4)
    err = assert_raises(ArgumentError) { @game.make_move(4) }
    assert_match(/occupied/i, err.message)
  end

  def test_raises_when_game_is_over
    # X wins on the top row: 0, 1, 2
    play(0, 6, 1, 7, 2)          # X wins
    assert_equal "x_wins", @game.state
    err = assert_raises(ArgumentError) { @game.make_move(3) }
    assert_match(/over/i, err.message)
  end

  def test_error_message_includes_position_for_occupied
    @game.make_move(5)
    err = assert_raises(ArgumentError) { @game.make_move(5) }
    assert_match(/5/, err.message)
  end

  def test_error_message_includes_position_for_out_of_range
    err = assert_raises(ArgumentError) { @game.make_move(9) }
    assert_match(/9/, err.message)
  end
end
