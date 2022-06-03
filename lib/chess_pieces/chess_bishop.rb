require_relative './chess_piece.rb'

class Bishop < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'bishop'
    @base_moves =
      [[-1, -1], [1, -1], [-1, 1], [1, 1]].reduce([]) do |moves, dirs|
        moves + (1..7).map do |num|
          dirs.map { |dir| dir * num }
        end
      end
  end

  private

  def base_positions
    @base_moves.map do |move|
      [position.first + move.first, position.last + move.last]
    end
  end

  def legal_next_positions(board)
    base_positions.each_slice(7).map do |pos_set|
      pos_set = in_range(pos_set)
      last_index = pos_set.index do |pos|
        board.any? { |piece| piece.position == pos }
      end
      pos_set[0..last_index].reject do |pos|
        board.any? { |piece| player(piece) && piece.position == pos }
      end
    end.flatten(1)
  end
end
