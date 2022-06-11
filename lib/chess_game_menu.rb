module GameMenu
  private

  def game_menu(player)
    until @menu_done
      puts game_menu_instructions
      case gets.chomp
      when /^1|help$/i then view_game_instructions
      when /^2|resign$/i then resign_game(player)
      when /^3|draw$/i then propose_draw(player)
      when /^7|back$/i then @menu_done = true
      end
    end
    @menu_done = false
  end

  def game_menu_instructions
    "Enter one of the following words to select the corresponding option:\r\n" \
    "  1. HELP (View instructions.)\r\n" \
    "  2. RESIGN (Resign current game to opponent. This will end the game.)\r\n" \
    "  3. DRAW (Propose a draw of current game.)\r\n" \
    "  4. SAVE (Save the current game.)\r\n" \
    "  5. LOAD (Load a different game.)\r\n" \
    "  6. MAIN (Exit to main menu.)\r\n" \
    "  7. BACK (Go back to current game.)\r\n"
  end

  def view_game_instructions
    puts "\r\n" + chess_introduction + "\r\n\r\n" + pos_input_instruction
    puts 'Press ENTER to continue.'
    gets.chomp
  end

  def resign_game(player)
    puts "WARNING: This will end the game.\r\n" \
         'Are you sure you wish to resign the game to your opponent? (Y/N)'
    return unless gets.chomp =~ /^yes|y$/i

    puts "#{@players[player.player_index ^ 1].name} has won the game!"
    @menu_done = true
    @game_over = true
  end

  def propose_draw(player)
    @menu_done = true
    opponent = @players[player.player_index ^ 1]
    puts "#{player.name} proposes a draw of the current game."
    puts "#{opponent.name}, do you accept the proposal of draw?"
    return draw_refusal(opponent) unless gets.chomp =~ /^yes|y$/i

    puts 'The game ends in a draw.'
    @game_over = true
  end

  def chess_introduction
    'Chess is a board game with two players, ' \
    "in which the goal is to checkmate the other player.\r\n" \
    'For information about the rules of the game, ' \
    'please visit http://www.chessvariants.org/d.chess/chess.html or ' \
    'https://en.wikipedia.org/wiki/Chess.'
  end

  def pos_input_instruction
    'In this program, all squares and positions should be entered ' \
    "using the format LETTER + NUMBER.\r\n" \
    'LETTER refers to the columns of the chess board ' \
    "and runs from A to H.\r\n" \
    'NUMBER refers to the rows of the chess board ' \
    "and runs from 1 to 8.\r\n" \
    "So, examples of valid inputs are:\r\n" \
    "     A1 F6 G8 H4\r\n" \
    'Inputs that do not follow this format will not be accepted.'
  end

  def draw_refusal(opponent)
    puts "#{opponent.name} does not accept the proposal of draw. " \
         'The current game will continue.'
    puts 'Press ENTER to continue.'
    gets.chomp
  end
end
