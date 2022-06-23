require_relative './chess_save_load_base.rb'

module Save
  include SaveLoadBaseMethods

  private

  def save_game
    set_up_save_location
    return unless (name = save_name)

    update_save_record(name, true)
    File.write("#{save_dir}/#{name}.yaml", to_yaml)
    puts "Game \"#{name}\" successfully saved!"

    offer_game_exit
  end

  def set_up_save_location
    Dir.mkdir(save_dir) unless Dir.exist?(save_dir)
    File.write(save_record, '') unless File.exist?(save_record)
  end

  def save_name
    save_file_num = Dir.glob("#{save_dir}/*.yaml")
                       .select { |file| File.file?(file) }
                       .size
    save_file_num < 20 ? new_save_name(15) : overwrite_name
  end

  def new_save_name(max_length)
    loop do
      puts 'Type GO BACK to return to the menu without saving.'
      puts "Please type a name for your save file (max #{max_length} " \
           'characters, letters and numbers only, no spaces).'
      return unless (name = valid_save_name(max_length))
      return name unless existing_save?(name)

      puts 'You already have a saved game with this name. ' \
           'Do you want to overwrite your previous save? Y/N'
      return name if /^yes$|^y$/i =~ gets.chomp
    end
  end

  def valid_save_name(max_length)
    loop do
      name = gets.chomp
      return if name.downcase == 'go back'
      return name if name =~ Regexp.new("^\\w{1,#{max_length}}$")

      puts save_name_error(name, max_length)
    end
  end

  def save_name_error(name, max_length)
    error = 'Error!'
    unless name.length.between?(1, max_length)
      error += "\r\nPlease enter a string between " \
               "1 and #{max_length} characters."
    end

    if name =~ /[^\w]/
      error += "\r\nPlease enter a string using letters/numbers only."
    end

    error
  end

  def overwrite_name
    display_saved_games
    puts 'Your save folder is full.'

    loop do
      puts 'Please type the name of an existing save file to overwrite, ' \
           'or type GO BACK to resume your game without saving.'
      return if (name = gets.chomp).downcase == 'go back'

      save_exists = existing_save?(name)
      return name if save_exists && confirm_overwrite(name)
      return if !save_exists && cancel_overwrite
    end
  end

  def confirm_overwrite(name)
    puts "Overwrite the save file named \"#{name}\"? Y/N"
    gets.chomp =~ /^yes$|^y$/i
  end

  def cancel_overwrite
    puts 'There is no save file with this name. ' \
         'Resume game without saving? Y/N'
    gets.chomp =~ /^yes$|^y$|^go back$/i
  end

  def offer_game_exit
    @menu_done = true
    puts 'Exit to main menu? Y/N'
    return @game_over = true if gets.chomp =~ /^yes$|^y$/i

    puts 'Press ENTER to continue the current game.'
    gets
  end
end
