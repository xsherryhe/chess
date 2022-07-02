# frozen_string_literal: true

require_relative './chess_info.rb'
require_relative './chess_save_load_system/chess_save.rb'
require_relative './chess_save_load_system/chess_load.rb'

module GameMenu
  include Information
  include Save
  include LoadAndDelete

  private

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
    enter_to_continue
  end

  def pos_input_instruction
    'In this program, all squares and positions should be entered ' \
    "using the format LETTER + NUMBER.\r\n" \
    'LETTER refers to the columns of the chess board ' \
    "and runs from A to H.\r\n" \
    'NUMBER refers to the rows of the chess board ' \
    "and runs from 1 to 8.\r\n\r\n" \
    "Move inputs should be entered using the format:\r\n" \
    "(LETTER + NUMBER) to (LETTER + NUMBER)\r\n" \
    "So, examples of valid moves might be:\r\n#{valid_input_examples}\r\n" \
    'Inputs that do not follow this format will not be accepted.'
  end

  def valid_input_examples
    ['A2 to A3', 'F6 to E8', 'G8 to C8', 'H3 to D7']
      .map { |example| ' ' * 5 + example }
      .join("\r\n")
  end

  def resign_game
    puts "WARNING: This will end the game.\r\n" \
         'Are you sure you wish to resign the game to your opponent? (Y/N)'
    return unless gets.chomp =~ /^yes$|^y$/i

    puts "#{curr_opponent.name} has won the game!"
    exit_game
    exit_to_main_menu
  end

  def propose_draw
    @menu_done = true
    puts "#{curr_player.name} proposes a draw of the current game."
    return draw_refusal unless curr_opponent.accept_draw? =~ /^yes$|^y$/i

    puts 'The game ends in a draw.'
    @game_over = true
    exit_to_main_menu
  end

  def draw_refusal
    puts "#{curr_opponent.name} does not accept the proposal of draw. " \
         'The current game will continue.'
    enter_to_continue
  end

  def exit_game
    @menu_done = true
    @game_over = true
  end
end
