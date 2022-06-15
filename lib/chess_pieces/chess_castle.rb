module Castle
  private

  def castle_instruction
    "Castling is also available for this #{@name}. " \
    'Please enter the word CASTLE to make a castling move.'
  end

  def move_with_castle_instruction(move_num)
    move_instruction(move_num) + "\r\n" + castle_instruction
  end

  def error_with_castle_message
    error_message + "\r\n" + castle_instruction
  end

  def valid_castle_input(board, move_num)
    puts move_with_castle_instruction(move_num)
    input = gets.chomp
    until input =~ /^castle$/i ||
          legal_next_positions(board, move_num).include?(to_pos(input))
      puts error_with_castle_message
      input = gets.chomp
    end
    input
  end

  def valid_rook_input(rooks, move_num)
    puts rook_input_instruction(rooks, move_num)
    rook_position = to_pos(gets.chomp)
    chosen_rook = rooks.find { |rook| rook.position == rook_position }
    until chosen_rook
      puts rook_error_message
      rook_position = to_pos(gets.chomp)
      chosen_rook = rooks.find { |rook| rook.position == rook_position }
    end
    chosen_rook
  end

  def rook_input_instruction(rooks, move_num)
    valid_rook_display(rooks) +
      "\r\nPlease enter the square of the rook that you wish to castle with" +
      (move_num < 2 ? ', using the format LETTER + NUMBER.' : '.')
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
end
