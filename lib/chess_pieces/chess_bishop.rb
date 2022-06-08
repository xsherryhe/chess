require_relative './chess_piece.rb'

class Bishop < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'bishop'
    @symbol = ["\u2657", "\u265D"][player_index]
    @base_moves =
      ([-1, 1].product([-1, 1]) - [[0, 0]]).reduce([]) do |moves, dirs|
        moves + (1..7).map do |num|
          dirs.map { |dir| dir * num }
        end
      end
  end
end
