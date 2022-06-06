module Castle
  private

  def castle_instruction
    "Castling is also available for this #{@name}. " \
    'Please enter the word "castle" to make a castling move.'
  end

  def move_with_castle_instruction
    move_instruction + "\r\n" + castle_instruction
  end

  def error_with_castle_message
    error_message + "\r\n" + castle_instruction
  end

  def valid_castle_input
    puts move_with_castle_instruction
    input = gets.chomp
    until input =~ /^castle$/i ||
          @legal_next_positions.include?(to_pos(input))
      puts error_with_castle_message
      input = gets.chomp
    end
    input
  end
end
