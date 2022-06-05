require_relative './chess_piece.rb'

class King < Piece
  def initialize(player_index, starting_position)
    super
    @name = 'king'
    @base_moves = ([-1, 0, 1].product([-1, 0, 1]) - [[0, 0]])
    @moved = false
  end

  def can_castle?(rook, board)
    neither_moved?(rook) &&
      same_row?(rook) &&
      empty_between?(rook, board) &&
      path_never_checked?(rook, board)
  end

  def castle(rook, board); end

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

  def checked?(pos, board)
    board.any? do |piece|
      piece.legal_next_positions(board).include?(pos)
    end
  end

  def path_never_checked?(rook, board)
    path = castle_path(rook)
    (path.first..path.last).none? { |dir| checked?([dir, position.last], board) }
  end

  def castle_path(rook)
    [position.first,
     position.first + (rook.position.first <=> position.first) * 2].sort
  end
end
