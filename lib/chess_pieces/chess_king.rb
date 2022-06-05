require_relative './chess_piece.rb'

class King < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'king'
    @base_moves = ([-1, 0, 1].product([-1, 0, 1]) - [[0, 0]])
    @moved = false
  end

  def can_castle?(rook, board, move_num)
    neither_moved?(rook) &&
      same_row?(rook) &&
      empty_between?(rook, board) &&
      path_never_checked?(rook, board, move_num)
  end

  def castle(rook, board)
  end

  def checked?(pos, board, move_num)
    board.any? do |piece|
      opponent?(piece) &&
        piece.next_positions_with_check(board, move_num).include?(pos)
    end
  end

  private

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
end
