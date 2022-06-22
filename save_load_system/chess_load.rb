require_relative './chess_save_load_base.rb'

module Load
  include SaveLoadBaseMethods

  def load_game
    return unless save_dir_exists && (name = load_name)

    puts "Game \"#{name}\" successfully loaded!"
    puts 'Press ENTER to continue.'
    gets
    file = save_dir + "/#{name}.yaml"

    if is_a?(Game)
      update_from_yaml(file)
      @menu_done = true
    else Game.from_yaml(file).play
    end
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
