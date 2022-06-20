module SaveLoadBaseMethods
  private

  def save_dir
    "#{File.expand_path('..', __dir__)}/saves"
  end

  def save_record
    "#{save_dir}/save_record.txt"
  end

  def existing_save_name(name)
    Regexp.new("^#{name}$", true) =~ File.read(save_record)
  end

  def display_saved_games
    puts "SAVED GAMES:\r\n"
    File.readlines(save_record).each do |save|
      puts "  -#{save}"
    end
    puts "\r\n"
  end

  def update_save_record(name, add)
    record = File.readlines(save_record)
    record.reject! { |save| save.downcase == name.downcase }
    record << name if add
    File.open(save_record, 'w') do |record_file|
      record.each { |save| record_file.puts(save) }
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
end
