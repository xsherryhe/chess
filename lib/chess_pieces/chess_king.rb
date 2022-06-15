require_relative './chess_piece.rb'
require_relative './chess_castle.rb'

class King < Piece
  include Castle

  def initialize(player_index, starting_position)
    super
    @name = 'king'
    @symbol = ["\u2654", "\u265A"][player_index]
    @base_moves = ([-1, 0, 1].product([-1, 0, 1]) - [[0, 0]])
    @moved = false
  end

  def move(board, move_num)
    rooks_to_castle = board.select do |piece|
      player?(piece) && piece.is_a?(Rook) && can_castle?(piece, board, move_num)
    end
    rooks_to_castle.empty? ? super : move_with_castle(rooks_to_castle, board, move_num)
    @moved = true
  end

  def can_castle?(rook, board, move_num)
    neither_moved?(rook) && same_row?(rook) &&
      empty_between?(rook, board) && path_never_checked?(rook, board, move_num)
  end

  def castle(rook)
    @position = castle_king_position(rook)
    rook.position = castle_rook_position(rook)
  end

  def next_positions(board, *)
    in_range(base_positions).reject do |pos|
      board.any? { |piece| player?(piece) && piece.position == pos }
    end
  end

  def checked?(pos, board, move_num)
    board.any? do |piece|
      opponent?(piece) && piece.next_positions(board, move_num).include?(pos)
    end
  end

  private

  def serialize_vals
    super.merge({ moved: @moved })
  end

  def move_with_castle(rooks, board, move_num)
    input = valid_castle_input(board, move_num)
    return @position = to_pos(input) unless input =~ /^castle$/i

    chosen_rook = valid_rook_input(rooks, move_num)
    castle(chosen_rook)
  end

  def neither_moved?(rook)
    !rook.moved && !@moved
  end

  def same_row?(rook)
    position.last == rook.position.last
  end

  def empty_between?(rook, board)
    start, finish = [position.first, rook.position.first].sort
    board.none? do |piece|
      piece.position.last == position.last &&
        (start + 1...finish).include?(piece.position.first)
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
