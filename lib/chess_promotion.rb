module Promotion
  def promote(pawn)
    display_board
    puts "#{@players[@curr_player_index].name}, your pawn must promote."
    @board << valid_promote_class_input.new(@curr_player_index, pawn.position)
    @board.delete(pawn)
  end

  def valid_promote_class_input
    puts promote_class_input_instruction
    loop do
      class_index = %w[queen bishop knight rook].index(gets.chomp.downcase)
      return [Queen, Bishop, Knight, Rook][class_index] if class_index

      puts 'Invalid input! ' + promote_class_input_instruction
    end
  end

  def promote_class_input_instruction
    "Please enter the piece type to promote your pawn to:\r\n" \
    '  ' + %w[QUEEN BISHOP KNIGHT ROOK]
           .map.with_index(1) { |name, i| "#{i}. #{name}" }.join("\r\n  ")
  end
end
