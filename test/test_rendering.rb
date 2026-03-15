# frozen_string_literal: true

require_relative "test_helper"

class TestRendering < Minitest::Test
  include GameHelpers

  def setup
    @game = TicTacToe::Game.new
  end

  # ── to_s structure ───────────────────────────────────────────────────────────

  def test_to_s_is_a_string
    assert_kind_of String, @game.to_s
  end

  def test_to_s_has_exactly_three_rows
    # Three board rows + two separator lines = 5 lines total
    lines = @game.to_s.lines.map(&:chomp).reject(&:empty?)
    board_rows  = lines.reject { |l| l.start_with?("─") }
    assert_equal 3, board_rows.size
  end

  def test_to_s_contains_two_separator_lines
    sep_lines = @game.to_s.lines.count { |l| l.strip.start_with?("─") }
    assert_equal 2, sep_lines
  end

  def test_to_s_has_nine_empty_cell_markers_initially
    assert_equal 9, @game.to_s.scan("·").size
  end

  def test_to_s_x_count_matches_moves_made_by_x
    @game.make_move(0)           # X plays
    @game.make_move(1)           # O plays
    @game.make_move(2)           # X plays
    assert_equal 2, @game.to_s.scan("X").size
  end

  def test_to_s_o_count_matches_moves_made_by_o
    @game.make_move(0)
    @game.make_move(1)           # O plays
    assert_equal 1, @game.to_s.scan("O").size
  end

  def test_to_s_total_marks_plus_dots_equals_nine
    @game.make_move(0)
    @game.make_move(4)
    @game.make_move(8)
    marks = @game.to_s.scan(/[XO]/).size
    dots  = @game.to_s.scan("·").size
    assert_equal 9, marks + dots
  end

  # ── inspect ──────────────────────────────────────────────────────────────────

  def test_inspect_is_a_string
    assert_kind_of String, @game.inspect
  end

  def test_inspect_contains_current_player
    assert_match(/X|O/i, @game.inspect)
  end

  def test_inspect_contains_state
    assert_match(/playing|wins|draw/i, @game.inspect)
  end

  def test_inspect_contains_valid_moves
    assert_match(/valid moves/i, @game.inspect)
  end

  def test_inspect_contains_the_board
    # Board uses ─ and │ characters
    assert_match(/[─│]/, @game.inspect)
  end

  def test_inspect_changes_after_move
    before = @game.inspect
    @game.make_move(4)
    refute_equal before, @game.inspect
  end

  # ── position legend ──────────────────────────────────────────────────────────

  def test_position_legend_is_a_string
    assert_kind_of String, TicTacToe::Game.position_legend
  end

  def test_position_legend_contains_all_positions_0_through_8
    legend = TicTacToe::Game.position_legend
    (0..8).each { |i| assert_match(/#{i}/, legend) }
  end

  def test_position_legend_is_callable_multiple_times
    2.times { assert_kind_of String, TicTacToe::Game.position_legend }
  end
end
