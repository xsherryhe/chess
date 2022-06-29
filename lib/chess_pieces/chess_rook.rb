require_relative './chess_piece.rb'

class Rook < Piece
  attr_reader :moved

  def initialize(player_index, starting_position)
    super
    @name = 'rook'
    @symbol = ["\u2656", "\u265C"][player_index]
    @base_moves = [1, -1].reduce([]) do |moves, dir|
      move_set = (1..7).map { |num| [0, dir * num] }
      moves + move_set + move_set.map(&:reverse)
    end
    @moved = false
  end

  def move(goal_pos)
    super
    @moved = true
  end

  private

  def serialize_vals
    super.merge('data' => { 'moved' => @moved }) do |_, sup_d, new_d|
      sup_d.merge(new_d)
    end
  end
end
