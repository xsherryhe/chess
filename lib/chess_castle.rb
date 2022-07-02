module Castle
  def can_castle?
    !rooks_to_castle.empty?
  end

  private

  def castle
    king = player_king
    rook = curr_player.select_rook(rooks_to_castle, self)

    king.move(castle_king_position(king, rook), move_num)
    rook.move(castle_rook_position(king, rook), move_num)
  end

  def rooks_to_castle
    board.select do |piece|
      player?(piece) &&
        piece.is_a?(Rook) &&
        pieces_can_castle?(player_king, piece)
    end
  end

  def pieces_can_castle?(king, rook)
    neither_moved?(king, rook) && same_row?(king, rook) &&
      empty_between?(king, rook) && path_never_checked?(king, rook)
  end

  def neither_moved?(king, rook)
    !king.moved && !rook.moved
  end

  def same_row?(king, rook)
    king.position.last == rook.position.last
  end

  def empty_between?(king, rook)
    start, finish = [king.position.first, rook.position.first].sort
    row = king.position.last
    board.none? { |piece| in_path?(piece, row, start, finish) }
  end

  def in_path?(piece, row, start, finish)
    piece.position.last == row &&
      (start + 1...finish).include?(piece.position.first)
  end

  def path_never_checked?(king, rook)
    path = castle_path(king, rook)
    (path.first..path.last).none? do |dir|
      king.checked?([dir, king.position.last], board, move_num)
    end
  end

  def castle_path(king, rook)
    [king.position.first,
     king.position.first +
       (rook.position.first <=> king.position.first) * 2].sort
  end

  def castle_king_position(king, rook)
    [king.position.first + (rook.position.first <=> king.position.first) * 2,
     king.position.last]
  end

  def castle_rook_position(king, rook)
    [king.position.first + (king.position.first <=> rook.position.first),
     king.position.last]
  end
end
