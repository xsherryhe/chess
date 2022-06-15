module GameConditions
  def display_check_state
    return unless check

    puts color_message('check') + '. (Press ENTER to continue).'
    gets.chomp
  end

  def display_repetition_state
    update_history
    return unless @history.count(@history.last) >= 3

    display_board
    puts 'The same position with the same player to move has been repeated ' \
         'at least 3 times in the game.'
    puts "#{curr_player.name}, do you wish to claim a draw?"
    return draw_claim_refusal unless gets.chomp =~ /^yes$|^y$/i

    puts 'The game ends in a draw.'
    @game_over = true
  end

  def display_mate_state
    return unless no_legal_moves

    display_board
    check ? display_checkmate : display_stalemate
  end

  private

  def check
    player_king.checked?(player_king.position, @board, @move_num)
  end

  def update_history
    @history << YAML.dump(curr_player_index: @curr_player_index,
                          board: @board.map(&:serialize).sort)
  end

  def draw_claim_refusal
    puts "#{curr_player.name} does NOT claim a draw. The game continues."
    puts 'Press ENTER to continue.'
    gets.chomp
  end

  def draw_propose_refusal
    puts "#{curr_opponent.name} does not accept the proposal of draw. " \
         'The current game will continue.'
    puts 'Press ENTER to continue.'
    gets.chomp
  end

  def no_legal_moves
    @board.select { |piece| player?(piece) }
          .all? { |piece| piece.legal_next_positions(@board, @move_num).empty? }
  end

  def color_message(condition)
    "#{curr_opponent.color} gives #{condition} to #{curr_player.color}"
  end

  def display_checkmate
    puts color_message('checkmate') +
         ". #{curr_opponent.name} has won the game!"
    @game_over = true
  end

  def display_stalemate
    puts " #{curr_player.color} gets a stalemate. " \
         'The game is a draw.'
    @game_over = true
  end
end
