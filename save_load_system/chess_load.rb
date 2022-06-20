require_relative './chess_save_load_base.rb'
require_relative '../lib/chess.rb'

module Load
  include SaveLoadBaseMethods

  def load_game
    return unless (name = load_name)

    open_game = is_a?(Game)
    @menu_done = true if open_game

    file = save_dir + "/#{name}.yaml"
    open_game ? from_yaml(file) : Game.new(file)
  end

  private

  def load_name
    display_saved_games
    loop do
      puts 'Type GO BACK to return to the menu.'
      puts 'Please type the name of the game you wish to load.'
      return unless (name = valid_save_name(15))
      return name if existing_save_name(name)

      puts 'There is no save file with this name. ' \
           'Return to main menu? Y/N'
      return if gets.chomp =~ /^yes$|^y$/i
    end
  end
end
