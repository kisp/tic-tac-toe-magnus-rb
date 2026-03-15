# frozen_string_literal: true

require_relative "test_helper"

class TestIntegration < Minitest::Test
  include GameHelpers

  # ── Full game: human move sequence → X wins ──────────────────────────────────

  def test_x_wins_via_human_move_sequence
    g = TicTacToe::Game.new
    # X: 0,4,8 (main diagonal), O: 1,2
    [0, 1, 4, 2, 8].each { |m| g.make_move(m) }
    assert g.x_wins?
    assert_equal :x, g.winner
    assert g.over?
  end

  # ── Full game: human move sequence → O wins ──────────────────────────────────

  def test_o_wins_via_human_move_sequence
    g = TicTacToe::Game.new
    # O: 0,1,2 (top row), X sacrifices at 6,7,8
    [6, 0, 7, 1, 8, 2].each { |m| g.make_move(m) }
    assert g.o_wins?
    assert_equal :o, g.winner
    assert g.over?
  end

  # ── Human vs AI — human tries to win but AI always blocks ───────────────────

  def test_human_cannot_win_against_perfect_ai
    # Let the human (X) always try to extend their longest line;
    # the AI (O) always plays best_move.  Run a few starting moves.
    human_openers = [0, 2, 6, 8]  # corners — strongest human opening choices

    human_openers.each do |opener|
      g = TicTacToe::Game.new
      g.make_move(opener)          # Human (X) opens

      until g.over?
        if g.current_player == "o"
          g.make_move(g.best_move) # AI plays perfectly
        else
          g.make_move(g.valid_moves.first) # Human plays naively
        end
      end

      # A perfect AI must not lose
      refute g.o_wins? == false && g.x_wins?,
        "AI (O) lost after human opened at #{opener}\n#{g}"
    end
  end

  # ── AI vs AI always draws — run several times to confirm determinism ─────────

  def test_ai_vs_ai_is_deterministic
    results = 3.times.map do
      g = TicTacToe::Game.new
      g.make_move(g.best_move) until g.over?
      g.state
    end
    assert results.all? { |r| r == "draw" },
      "Expected all AI vs AI games to draw; got #{results.inspect}"
  end

  # ── Reset and replay ─────────────────────────────────────────────────────────

  def test_reset_and_replay_produces_independent_result
    g = TicTacToe::Game.new
    [0, 1, 2, 5, 3, 6, 4, 8, 7].each { |m| g.make_move(m) }  # draw
    assert_equal "draw", g.state

    g.reset
    [0, 6, 1, 7, 2].each { |m| g.make_move(m) }               # X wins
    assert_equal "x_wins", g.state
  end

  # ── Thread safety: two games run concurrently without corrupting state ───────

  def test_concurrent_games_do_not_corrupt_each_other
    threads = 4.times.map do
      Thread.new do
        g = TicTacToe::Game.new
        g.make_move(g.best_move) until g.over?
        g.state
      end
    end
    results = threads.map(&:value)
    assert results.all? { |r| r == "draw" },
      "Concurrent AI vs AI games should all draw; got #{results.inspect}"
  end

  # ── Valid-move set is updated correctly across a whole game ──────────────────

  def test_valid_moves_shrinks_monotonically_throughout_game
    g = TicTacToe::Game.new
    prev_size = 9
    until g.over?
      current_size = g.valid_moves.size
      assert current_size < prev_size,
        "Valid moves did not shrink: was #{prev_size}, still #{current_size}"
      prev_size = current_size
      g.make_move(g.valid_moves.first)
    end
  end

  # ── Smoke test every position as X's first move ─────────────────────────────

  def test_ai_can_respond_to_every_possible_opening_move
    9.times do |pos|
      g = TicTacToe::Game.new
      g.make_move(pos)            # Human opens anywhere
      bm = g.best_move            # AI should always find a valid response
      assert_kind_of Integer, bm,
        "AI returned nil after human opened at #{pos}"
      assert_includes g.valid_moves, bm,
        "AI move #{bm} is not valid after human opened at #{pos}"
    end
  end
end
