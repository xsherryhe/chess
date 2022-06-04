require_relative './chess_piece.rb'

class Rook < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'rook'
    @base_moves = [1, -1].reduce([]) do |moves, dir|
      move_set = (1..7).map { |num| [0, dir * num] }
      moves + move_set + move_set.map(&:reverse)
    end
  end
end
