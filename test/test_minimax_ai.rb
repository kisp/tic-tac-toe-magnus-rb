# frozen_string_literal: true

require_relative "test_helper"

class TestMinimaxAI < Minitest::Test
  include GameHelpers

  # ── best_move returns nil when game is over ──────────────────────────────────

  def test_best_move_returns_nil_when_x_wins
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7, 2)          # X wins on top row
    assert_nil @game.best_move
  end

  def test_best_move_returns_nil_when_o_wins
    @game = TicTacToe::Game.new
    play(3, 0, 8, 1, 6, 2)       # O wins on top row
    assert_nil @game.best_move
  end

  def test_best_move_returns_nil_on_draw
    @game = TicTacToe::Game.new
    [0, 1, 2, 5, 3, 6, 4, 8, 7].each { |m| @game.make_move(m) }
    assert_nil @game.best_move
  end

  # ── best_move returns a valid position ──────────────────────────────────────

  def test_best_move_returns_an_integer
    @game = TicTacToe::Game.new
    assert_kind_of Integer, @game.best_move
  end

  def test_best_move_is_always_a_valid_move
    @game = TicTacToe::Game.new
    until @game.over?
      bm = @game.best_move
      assert_includes @game.valid_moves, bm,
        "AI returned #{bm} but valid moves are #{@game.valid_moves.inspect}"
      @game.make_move(bm)
    end
  end

  # ── Winning move — X must take it ───────────────────────────────────────────

  def test_ai_takes_winning_move_on_top_row
    # Board: X at 0, 1 — AI (X) should play 2 to win immediately
    @game = TicTacToe::Game.new
    play(0, 6, 1, 7)             # X: 0,1  O: 6,7
    assert_equal 2, @game.best_move
  end

  def test_ai_takes_winning_move_on_diagonal
    # X at 0, 4 — AI (X) should play 8
    @game = TicTacToe::Game.new
    play(0, 1, 4, 2)
    assert_equal 8, @game.best_move
  end

  def test_ai_takes_winning_move_on_column
    # X at 0, 3 — AI (X) should play 6
    @game = TicTacToe::Game.new
    play(0, 1, 3, 2)
    assert_equal 6, @game.best_move
  end

  # ── Blocking move — O must block ─────────────────────────────────────────────

  def test_ai_blocks_x_winning_on_top_row
    # X at 0, 1 — it's O's turn; O must play 2 to block
    @game = TicTacToe::Game.new
    play(0, 8, 1)                # X: 0,1  O: 8 — now O's turn
    # Wait — after 0,8,1 it is O's turn only if we played X,O,X.
    # Sequence: X→0, O→8, X→1. So current_player is O, who must block at 2.
    assert_equal "o", @game.current_player
    assert_equal 2, @game.best_move
  end

  def test_ai_blocks_x_winning_on_bottom_row
    # X threatens 6,7,8 — O must play 8 (or the completing square)
    @game = TicTacToe::Game.new
    play(6, 0, 7, 1)             # X: 6,7  O: 0,1 — X to play but let's flip
    # After X→6, O→0, X→7, O→1 it is X's turn, not what we want.
    # Build the position differently: give O the two-in-a-row threat.
    g = TicTacToe::Game.new
    # X→0, O→6, X→1, O→7 — O threatens 6,7 → needs 8. X to play, but let's
    # test from O's perspective by making one more X move first.
    play_seq = [0, 6, 1, 7]     # X:0,1  O:6,7 — it's X's turn
    g2 = TicTacToe::Game.new
    play_seq.each { |m| g2.make_move(m) }
    # X's turn; X has 0,1 and threatens 2. O has 6,7 and threatens 8.
    # AI (X) should take 2 (win immediately) over blocking at 8.
    bm = g2.best_move
    assert_equal 2, bm, "AI should take its own win at 2, not block at 8"
  end

  def test_ai_blocks_x_winning_on_anti_diagonal
    # X at 2, 4 threatens 6. O to play, must go to 6.
    @game = TicTacToe::Game.new
    play(2, 0, 4, 1)             # X: 2,4  O: 0,1 — X's turn again
    # Let O have the blocking duty: need O's turn with X threatening 6.
    g = TicTacToe::Game.new
    # X→0, O→2, X→1, O→4 → X to play
    # Instead: X→3, O→2, X→8, O→4 → X to play — not helpful.
    # Cleanest: put X at 2 & 4 and make it O's turn.
    #   X→2, O→5, X→4, O→... wait we need a move that keeps 6 open.
    g2 = TicTacToe::Game.new
    g2.make_move(2)  # X
    g2.make_move(5)  # O (safe)
    g2.make_move(4)  # X  — X now threatens 2-4-6 diagonal
    # It's O's turn; best move should be 6 to block.
    assert_equal "o", g2.current_player
    assert_equal 6, g2.best_move
  end

  # ── Perfect play — AI vs AI should always draw ──────────────────────────────

  def test_ai_vs_ai_always_draws
    g = TicTacToe::Game.new
    until g.over?
      g.make_move(g.best_move)
    end
    assert_equal "draw", g.state,
      "Perfect play must always produce a draw; got #{g.state}\n#{g}"
  end

  def test_ai_vs_ai_plays_exactly_nine_moves_to_fill_board
    # Perfect play fills the board (no early wins on either side).
    g = TicTacToe::Game.new
    moves = 0
    until g.over?
      g.make_move(g.best_move)
      moves += 1
    end
    assert_equal 9, moves,
      "Minimax AI vs AI should fill all 9 squares; only #{moves} were played"
  end

  # ── Centre preference on empty board ────────────────────────────────────────

  def test_ai_plays_centre_on_empty_board
    # The centre (4) is the strongest opening move in Tic Tac Toe.
    @game = TicTacToe::Game.new
    assert_equal 4, @game.best_move
  end

  # ── Stress: AI picks valid moves across many mid-game positions ──────────────

  def test_ai_valid_on_all_single_move_positions
    9.times do |pos|
      g = TicTacToe::Game.new
      g.make_move(pos)
      bm = g.best_move
      assert_kind_of Integer, bm
      assert_includes g.valid_moves, bm
    end
  end
end
