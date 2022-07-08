# frozen_string_literal: true

require_relative './chess_menu.rb'
require_relative './chess_save_load_system/chess_save.rb'
require_relative './chess_save_load_system/chess_load.rb'

module GameMenu
  include Menu
  include Save
  include LoadAndDelete

  private

  def game_menu
    access_menu
  end

  def menu_options
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
    input = gets.chomp
    system 'clear'
    case input
    when /^1$|^help$/i then display_game_instructions
    when /^2$|^resign$/i then resign_game
    when /^3$|^draw$/i then propose_draw
    when /^4$|^save$/i then save_game
    when /^5$|^load$/i then load_game
    when /^6$|^delete$/i then delete_game
    when /^7$|^main$/i then exit_game
    when /^8$|^back$/i then @menu_done = true
    else @invalid_input = true
    end
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
