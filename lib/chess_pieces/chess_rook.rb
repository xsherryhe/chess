require_relative './chess_piece.rb'

class Rook < Piece
  attr_reader :moved

  def initialize(player_index, starting_position)
    super
    @name = 'rook'
    @base_moves = [1, -1].reduce([]) do |moves, dir|
      move_set = (1..7).map { |num| [0, dir * num] }
      moves + move_set + move_set.map(&:reverse)
    end
    @moved = false
  end

  def move(board, move_num)
    @moved = true
    king = king_to_castle(board, move_num)
    king ? move_with_castle(king, board, move_num) : super
  end

  private

  def king_to_castle(board, move_num)
    king = player_king(board)
    king if king.can_castle?(self, board, move_num)
  end

  def move_with_castle(king, board, move_num)
    input = valid_castle_input(board, move_num)
    return @position = to_pos(input) unless input =~ /^castle$/i

    king.castle(self, board)
  end

  def castle_instruction
    'Castling is also available for this rook. ' \
    'Please enter the word "castle" to make a castling move.'
  end

  def move_with_castle_instruction
    move_instruction + "\r\n" + castle_instruction
  end

  def error_with_castle_message
    error_message + "\r\n" + castle_instruction
  end

  def valid_castle_input(board, move_num)
    puts move_with_castle_instruction
    input = gets.chomp
    until input =~ /^castle$/i ||
          legal_next_positions(board, move_num).include?(to_pos(input))
      puts error_with_castle_message
      input = gets.chomp
    end
    input
  end
end
