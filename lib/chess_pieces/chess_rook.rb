require_relative './chess_piece.rb'
require_relative './chess_castle.rb'

class Rook < Piece
  include Castle
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

  def move(board, move_num)
    king = king_to_castle(board, move_num)
    king ? move_with_castle(king, board, move_num) : super
    @moved = true
  end

  private

  def serialize_vals
    super.merge(data: { :@moved => @moved }) do |_, super_d, new_d|
      super_d.merge(new_d)
    end
  end

  def king_to_castle(board, move_num)
    king = player_king(board)
    king if king.can_castle?(self, board, move_num)
  end

  def move_with_castle(king, board, move_num)
    input = valid_castle_input(board, move_num)
    return @position = to_pos(input) unless input =~ /^castle$/i

    king.castle(self)
  end
end
