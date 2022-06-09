# frozen_string_literal: true

require_relative '.././chess_base.rb'

class Piece
  include BaseMethods

  attr_accessor :position
  attr_reader :player_index, :symbol

  def initialize(player_index, starting_position)
    @player_index = player_index
    @position = starting_position
  end

  def move(board, move_num)
    @position = valid_pos_input(board, move_num)
  end

  def legal_next_positions(board, move_num)
    king = player_king(board)
    @illegal_check_next_positions, legal_next_positions =
      next_positions(board, move_num).partition do |next_pos|
        king_in_check?(king, next_pos, board, move_num)
      end
    legal_next_positions
  end

  def next_positions(board, *)
    base_positions.each_slice(7).map do |pos_set|
      pos_set = in_range(pos_set)
      last_index = pos_set.index do |pos|
        board.any? { |piece| piece.position == pos }
      end
      pos_set[0..last_index].reject do |pos|
        board.any? { |piece| player?(piece) && piece.position == pos }
      end
    end.flatten(1)
  end

  private

  def king_in_check?(king, next_pos, board, move_num)
    moved_piece = clone
    moved_piece.position = next_pos
    moved_board = board - [self] + [moved_piece]
    capture_pieces(moved_piece, moved_board)
    king.checked?((moved_piece.is_a?(King) ? moved_piece : king).position,
                  moved_board, move_num)
  end

  def move_instruction
    "Please enter the square to move the #{@name}, "\
    'using the format LETTER + NUMBER (e.g., "A1").'
  end

  def error_message(new_pos)
    message = "Please enter a square for the #{@name} " \
    'that can be reached with a legal move. ' \
    'Please use the format LETTER + NUMBER (e.g., "A1").'
    if @illegal_check_next_positions.include?(new_pos)
      message = "This move would leave your king in check.\r\n" +
                message
    end
    (new_pos ? 'Illegal move! ' : 'Invalid input! ') + message
  end

  def valid_pos_input(board, move_num)
    puts move_instruction
    new_pos = to_pos(gets.chomp)
    until legal_next_positions(board, move_num).include?(new_pos)
      puts error_message(new_pos)
      new_pos = to_pos(gets.chomp)
    end
    new_pos
  end

  def base_positions
    @base_moves.map do |move|
      [position.first + move.first, position.last + move.last]
    end
  end

  def in_range(positions)
    positions.select do |pos|
      pos.all? { |dir| dir.between?(0, 7) }
    end
  end
end
