module BaseMethods
  private

  def player?(piece, player_index = @player_index || @curr_player_index)
    piece.player_index == player_index
  end

  def opponent?(piece, player_index = @player_index || @curr_player_index)
    piece.player_index == player_index ^ 1
  end

  def player_king(board = @board)
    board.find { |piece| piece.is_a?(King) && player?(piece) }
  end

  def capture_pieces(target_piece, board = @board)
    board.delete_if do |piece|
      opponent?(piece) &&
        piece.position == target_piece.position ||
        target_piece.is_a?(Pawn) && target_piece.en_passant &&
          target_piece.en_passant.last == piece.position
    end
  end

  def to_pos(input)
    return unless input.length == 2

    col, row = input.upcase.chars
    pos = [col.ord - 65, row.to_i - 1]
    pos.all? { |dir| dir.between?(0, 7) } ? pos : nil
  end
end
