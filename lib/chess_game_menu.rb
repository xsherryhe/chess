# frozen_string_literal: true

require_relative './chess_info.rb'
require_relative './chess_save_load_system/chess_save.rb'
require_relative './chess_save_load_system/chess_load.rb'

module GameMenu
  include Information
  include Save
  include LoadAndDelete

  private

  def game_menu_instruction
    ' (Or enter the word MENU to view other game options.)'
  end

  def game_menu
    until @menu_done
      puts game_menu_options
      select_menu_option
    end
    @menu_done = false
  end

  def game_menu_options
    "Enter one of the following commands:\r\n" +
      ['HELP (View instructions.)',
       'RESIGN (Resign current game to opponent. This will end the game.)',
       'DRAW (Propose a draw of current game.)',
       'SAVE (Save the current game.)', 'LOAD (Load a different game.)',
       'DELETE (Delete a saved game.)', 'MAIN (Exit to main menu.)',
       'BACK (Go back to current game.)']
      .map.with_index(1) { |option, i| "  #{i}. #{option}" }.join("\r\n")
  end

  def select_menu_option
    case gets.chomp
    when /^1$|^help$/i then display_game_instructions
    when /^2$|^resign$/i then resign_game
    when /^3$|^draw$/i then propose_draw
    when /^4$|^save$/i then save_game
    when /^5$|^load$/i then load_game
    when /^6$|^delete$/i then delete_game
    when /^7$|^main$/i then exit_game
    when /^8$|^back$/i then @menu_done = true
    else puts 'Invalid input!'
    end
  end

  def display_game_instructions
    puts "\r\n" + chess_introduction + "\r\n\r\n" + pos_input_instruction
    puts 'Press ENTER to continue.'
    gets
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

  def resign_game
    puts "WARNING: This will end the game.\r\n" \
         'Are you sure you wish to resign the game to your opponent? (Y/N)'
    return unless gets.chomp =~ /^yes$|^y$/i

    puts "#{curr_opponent.name} has won the game!"
    exit_game
  end

  def propose_draw
    @menu_done = true
    puts "#{curr_player.name} proposes a draw of the current game."
    puts "#{curr_opponent.name}, do you accept the proposal of draw?"
    return draw_propose_refusal unless gets.chomp =~ /^yes$|^y$/i

    puts 'The game ends in a draw.'
    @game_over = true
  end

  def exit_game
    @menu_done = true
    @game_over = true
  end
end
