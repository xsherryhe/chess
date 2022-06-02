require_relative './chess_piece.rb'

class Knight < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'knight'
    @base_moves = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
                  .map { |x, y| [x * 1, y * 2] }
    @base_moves += @base_moves.map(&:reverse)
  end

  private

  def legal_next_positions(board)
    base_positions.reject do |pos|
      board.any? { |piece| player(piece) && piece.position == pos }
    end
  end
end
