# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"

# Test that require "tic_tac_toe_magnus" works (gem name == require name convention).
require "tic_tac_toe_magnus"

class TestRequireName < Minitest::Test
  def test_tic_tac_toe_module_is_defined
    assert defined?(TicTacToe), "TicTacToe module should be defined after require 'tic_tac_toe_magnus'"
  end

  def test_game_class_is_accessible
    assert defined?(TicTacToe::Game), "TicTacToe::Game should be accessible"
  end

  def test_can_instantiate_game
    game = TicTacToe::Game.new
    assert_instance_of TicTacToe::Game, game
  end
end
