require_relative './chess_piece.rb'
require_relative './chess_castle.rb'

class King < Piece
  include Castle

  def initialize(player_index, starting_position)
    super
    @name = 'king'
    @base_moves = ([-1, 0, 1].product([-1, 0, 1]) - [[0, 0]])
    @moved = false
  end

  def move(board, move_num)
    @moved = true
    rooks_to_castle = board.select do |piece|
      player?(piece) && piece.is_a?(Rook) && can_castle?(piece, board, move_num)
    end
    rooks_to_castle.empty? ? super : move_with_castle(rooks_to_castle, board, move_num)
  end

  def can_castle?(rook, board, move_num)
    neither_moved?(rook) &&
      same_row?(rook) &&
      empty_between?(rook, board) &&
      path_never_checked?(rook, board, move_num)
  end

  def castle(rook)
    @position = castle_king_position(rook)
    rook.position = castle_rook_position(rook)
  end

  def checked?(pos, board, move_num)
    board.any? do |piece|
      opponent?(piece) && piece.next_positions(board, move_num).include?(pos)
    end
  end

  private

  def move_with_castle(rooks, board, move_num)
    update_next_positions(board, move_num)
    input = valid_castle_input
    return @position = to_pos(input) unless input =~ /^castle$/i

    chosen_rook = valid_rook_input(rooks)
    castle(chosen_rook)
  end

  def valid_rook_input(rooks)
    puts rook_input_instruction
    rook_position = to_pos(gets.chomp)
    chosen_rook = rooks.find { |rook| rook.position == rook_position }
    until chosen_rook
      puts rook_error_message
      rook_position = to_pos(gets.chomp)
      chosen_rook = rooks.find { |rook| rook.position == rook_position }
    end
    chosen_rook
  end

  def rook_input_instruction
    valid_rook_display +
      "\r\nPlease enter the square of the rook that you wish to castle with, " \
      'using the format LETTER + NUMBER (e.g., "A1").'
  end

  def valid_rook_display(rooks)
    'Your king can castle with ' \
    "the following rook#{rooks.size > 1 ? 's' : ''} at: " +
      rooks.map do |rook|
        ('A'..'H').to_a[rook.position.first] + (rook.position.last + 1).to_s
      end.join(', ')
  end

  def rook_error_message
    'Invalid square! Please enter the square of a valid rook to castle with. ' \
    'Please use the format LETTER + NUMBER (e.g., "A1").'
  end

  def neither_moved?(rook)
    !rook.moved && !moved
  end

  def same_row?(rook)
    position.last == rook.position.last
  end

  def empty_between?(rook, board)
    board.none? do |piece|
      piece.position.last == position.last &&
        piece.position.first.between?(*[position.first,
                                        rook.position.first].sort)
    end
  end

  def path_never_checked?(rook, board, move_num)
    path = castle_path(rook)
    (path.first..path.last).none? do |dir|
      checked?([dir, position.last], board, move_num)
    end
  end

  def castle_path(rook)
    [position.first,
     position.first + (rook.position.first <=> position.first) * 2].sort
  end

  def castle_king_position(rook)
    [position.first + (rook.position.first <=> position.first) * 2,
     position.last]
  end

  def castle_rook_position(rook)
    [position.first + (position.first <=> rook.position.first),
     position.last]
  end
end
