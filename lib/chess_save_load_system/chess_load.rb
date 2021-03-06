require_relative './chess_save_load_base.rb'

module LoadAndDelete
  include SaveLoadBaseMethods

  private

  def load_game
    return unless check_saved_games && (name = existing_save_name('load'))

    puts "Game \"#{name}\" successfully loaded!"
    enter_to_continue
    file = "#{save_dir}/#{name}.yaml"

    if is_a?(Game)
      update_from_yaml(file)
      @menu_done = true
    else Game.from_yaml(file).play
    end
  end

  def delete_game
    return unless check_saved_games

    loop do
      return unless (name = existing_save_name('delete'))

      update_save_record(name, false)
      File.delete("#{save_dir}/#{name}.yaml")
      puts "Game \"#{name}\" successfully deleted!"
      return exit_to_menu unless delete_another_game?
    end
  end

  def any_saved_games?
    Dir.exist?(save_dir) &&
      !Dir.glob("#{save_dir}/*.yaml").select { |file| File.file?(file) }.empty?
  end

  def check_saved_games
    return true if any_saved_games?

    puts 'You have no saved games.'
    exit_to_menu
    false
  end

  def existing_save_name(action)
    display_saved_games
    loop do
      puts 'Type GO BACK to return to the menu.'
      puts "Please type the name of the game you wish to #{action}."
      return if (name = gets.chomp.downcase) == 'go back'
      return name if existing_save?(name)

      puts 'There is no save file with this name. ' \
           'Return to the menu? Y/N'
      return if gets.chomp =~ /^yes$|^y$|^go back$/i
    end
  end

  def delete_another_game?
    return unless any_saved_games?

    puts 'Would you like to delete another game? Y/N'
    gets.chomp =~ /^yes$|^y$/i
  end
end
