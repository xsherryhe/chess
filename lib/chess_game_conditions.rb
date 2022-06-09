module GameConditions
  private

  def display_mate_state
    return unless no_legal_moves

    display_board
    check ? display_checkmate : display_stalemate
  end

  def no_legal_moves
    @board.select { |piece| player?(piece) }
          .all? { |piece| piece.legal_next_positions(@board, @move_num).empty? }
  end

  def color_message(condition)
    [@curr_player_index ^ 1, @curr_player_index].map do |player_index|
      @players[player_index].color
    end.join(" gives #{condition} to ")
  end

  def check
    player_king.checked?(player_king.position, @board, @move_num)
  end

  def display_check_state
    return unless check

    puts color_message('check') + '. (Press ENTER to continue).'
    gets.chomp
  end

  def display_checkmate
    puts color_message('checkmate') +
         ". #{@players[@curr_player_index ^ 1].name} has won the game!"
    @game_over = true
  end

  def display_stalemate
    puts " #{@players[@curr_player_index].color} gets a stalemate. " \
         'The game is a draw.'
    @game_over = true
  end
end
