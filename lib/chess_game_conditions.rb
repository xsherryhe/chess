module GameConditions
  def display_check_state
    return if @game_over
    return unless check

    display_board
    puts color_message('check') + '. (Press ENTER to continue).'
    gets
  end

  def display_draw_claim_state
    return if @game_over

    repetition = repetition_of_positions?
    idle_moves = fifty_idle_moves?
    return unless repetition || idle_moves

    display_board
    puts draw_claim_message(repetition, idle_moves)
    return draw_claim_refusal unless curr_player.claim_draw? =~ /^yes$|^y$/i

    puts 'The game ends in a draw.'
    @game_over = true
    exit_to_main_menu
  end

  def display_mate_state
    return unless no_legal_moves

    display_board
    check ? display_checkmate : display_stalemate
  end

  private

  def check
    player_king.checked?(player_king.position, board, move_num)
  end

  def repetition_of_positions?
    @history.count(@history.last) >= 3
  end

  def fifty_idle_moves?
    @idle_moves >= 100
  end

  def draw_claim_message(repetition, idle_moves)
    repetition_message = 'The same position with the same player to move ' \
                 'has been repeated at least 3 times in the game.'
    idle_moves_message = 'there have been 50 consecutive moves of both ' \
                         'players without any piece taken or any pawn move.'
    if repetition && idle_moves
      [repetition_message, idle_moves_message].join(' Also, ')
    elsif repetition
      repetition_message
    else idle_moves_message.capitalize
    end
  end

  def draw_claim_refusal
    puts "#{curr_player.name} does NOT claim a draw. The game continues."
    enter_to_continue
  end

  def no_legal_moves
    board.select { |piece| player?(piece) }
         .all? { |piece| piece.legal_next_positions(board, move_num).empty? }
  end

  def color_message(condition)
    "#{curr_opponent.color} gives #{condition} to #{curr_player.color}"
  end

  def display_checkmate
    puts color_message('checkmate') +
         ". #{curr_opponent.name} has won the game!"
    @game_over = true
    exit_to_main_menu
  end

  def display_stalemate
    puts " #{curr_player.color} gets a stalemate. " \
         'The game is a draw.'
    @game_over = true
    exit_to_main_menu
  end
end
