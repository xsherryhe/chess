require_relative './chess_menu.rb'
require_relative './chess_game.rb'
require_relative './chess_save_load_system/chess_load.rb'

module Chess
  extend Menu
  extend LoadAndDelete

  def self.run
    access_menu
  end

  def self.menu_options
    "MAIN MENU: What would you like to do?\r\n" \
    "Enter one of the following commands:\r\n" +
      ['NEW (Start a new game with two human players.)',
       'COMPUTER (Start a new game with a computer player.)',
       'LOAD (Load a saved game.)',
       'DELETE (Delete a saved game.)',
       'HELP (View instructions.)',
       'EXIT (Exit the program.)']
      .map.with_index(1) { |option, i| "  #{i}. #{option}" }.join("\r\n")
  end

  def self.select_menu_option
    input = gets.chomp
    system 'clear'
    case input
    when /^1$|^new$/i then Game.new.play
    when /^2$|^computer$/i then Game.new(false, true).play
    when /^3$|^load$/i then load_game
    when /^4$|^delete$/i then delete_game
    when /^5$|^help$/i then display_information
    when /^6$|^exit$/i then @menu_done = true
    else @invalid_input = true
    end
  end
end
