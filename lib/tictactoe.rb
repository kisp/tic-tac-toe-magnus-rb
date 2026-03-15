# frozen_string_literal: true

require_relative "tictactoe/version"
# Load the compiled Rust extension (.so / .bundle)
require "tictactoe/tictactoe"

module TicTacToe
  # TicTacToe::Game is defined in Rust (ext/tictactoe/src/lib.rs).
  #
  # This file adds idiomatic Ruby sugar on top of the raw bindings so that
  # callers never have to think about the underlying C/Rust layer.
  class Game
    # Symbols returned by #state
    STATES = %i[playing x_wins o_wins draw].freeze

    # Pretty-print the board followed by game status.
    def inspect
      lines = [to_s]
      lines << ""
      lines << "  Current player : #{current_player.upcase}"
      lines << "  State          : #{state}"
      lines << "  Valid moves    : #{valid_moves.join(', ')}"
      lines.join("\n")
    end

    # Returns true when no more moves can be made.
    def over?
      state != "playing"
    end

    # Returns true when the game ended in a draw.
    def draw?
      state == "draw"
    end

    # Returns true when X has won.
    def x_wins?
      state == "x_wins"
    end

    # Returns true when O has won.
    def o_wins?
      state == "o_wins"
    end

    # Returns the winning player symbol (:x / :o) or nil.
    def winner
      case state
      when "x_wins" then :x
      when "o_wins" then :o
      end
    end

    # Human-readable position legend printed once so players know the mapping.
    def self.position_legend
      <<~LEGEND
        Board positions:

          0 │ 1 │ 2
         ───┼───┼───
          3 │ 4 │ 5
         ───┼───┼───
          6 │ 7 │ 8
      LEGEND
    end
  end
end
