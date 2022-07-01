require_relative './chess_info.rb'
require_relative './chess_game.rb'
require_relative './chess_save_load_system/chess_load.rb'

module Chess
  extend Information
  extend LoadAndDelete

  def self.run
    until @menu_done
      puts menu_options
      select_menu_option
    end
    @menu_done = false
  end

  def self.menu_options
    "\r\nMAIN MENU: What would you like to do?\r\n" \
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
    case gets.chomp
    when /^1$|^new$/i then Game.new.play
    when /^2$|^computer$/i then Game.new(false, true).play
    when /^2$|^load$/i then load_game
    when /^3$|^delete$/i then delete_game
    when /^4$|^help$/i then display_information
    when /^5$|^exit$/i then @menu_done = true
    else puts 'Invalid input!'
    end
  end

  def self.display_information
    puts "\r\n" + chess_introduction + "\r\n"
    puts 'Press ENTER to continue.'
    gets
  end
end
