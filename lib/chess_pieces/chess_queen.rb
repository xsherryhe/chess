require_relative './chess_piece.rb'

class Queen < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'queen'
    @base_moves =
      ([-1, 0, 1].product([-1, 0, 1]) - [[0, 0]]).reduce([]) do |moves, dirs|
        moves + (1..7).map do |num|
          dirs.map { |dir| dir * num }
        end
      end
  end
end
