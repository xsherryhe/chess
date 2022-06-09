module GameConditions
  private

  def evaluate_game_conditions
  end

  def evaluate_check
    checked_color, checking_color =
      [@curr_player_index, @curr_player_index ^ 1].map do |player_index|
        @players[player_index].color
      end
    king = player_king
    return unless king.checked?(king.position, @board, @move_num)

    puts "#{checking_color} gives check to #{checked_color}." \
         '(Press ENTER to continue).'
    gets.chomp
  end

  def evaluate_checkmate
  end
end
