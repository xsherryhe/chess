module Castle
  private

  def castle_instruction
    'Castling is also available. ' \
    'Enter the word CASTLE to make a castling move.'
  end

  def castle
    king = player_king
    rook = valid_rook_input(rooks_to_castle)

    king.position = castle_king_position(king, rook)
    rook.position = castle_rook_position(king, rook)
  end

  def valid_rook_input(rooks)
    return rooks.first if rooks.size == 1

    puts rook_input_instruction(rooks)
    loop do
      rook_position = to_pos(gets.chomp)
      chosen_rook = rooks.find { |rook| rook.position == rook_position }
      return chosen_rook if chosen_rook

      puts rook_error_message
    end
  end

  def rook_input_instruction(rooks)
    valid_rook_display(rooks) +
      "\r\nPlease enter the square of the rook " \
      'that you would like your king to castle with' +
      (@move_num < 2 ? ', using the format "LETTER + NUMBER".' : '.')
  end

  def valid_rook_display(rooks)
    'Your king can castle with the following rooks at: ' +
      rooks.map do |rook|
        ('A'..'H').to_a[rook.position.first] + (rook.position.last + 1).to_s
      end.join(', ')
  end

  def rook_error_message
    'Invalid square! Please enter the square of a valid rook to castle with. ' \
    'Please use the format "LETTER + NUMBER" (e.g., "A1").'
  end

  def rooks_to_castle
    @board.select do |piece|
      player?(piece) && piece.is_a?(Rook) && can_castle?(player_king, piece)
    end
  end

  def can_castle?(king, rook)
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
    @board.none? do |piece|
      piece.position.last == king.position.last &&
        (start + 1...finish).include?(piece.position.first)
    end
  end

  def path_never_checked?(king, rook)
    path = castle_path(king, rook)
    (path.first..path.last).none? do |dir|
      king.checked?([dir, king.position.last], @board, @move_num)
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
