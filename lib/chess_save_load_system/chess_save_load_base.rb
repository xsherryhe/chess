module SaveLoadBaseMethods
  private

  def save_dir
    "#{File.expand_path('../..', __dir__)}/saves"
  end

  def save_record
    "#{save_dir}/save_record.txt"
  end

  def existing_save?(name)
    File.readlines(save_record).map(&:downcase).include?(name.downcase + "\n")
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
    record.reject! { |save| name.downcase == save.downcase }
    record << name if add
    File.open(save_record, 'w') do |record_file|
      record.each { |save| record_file.puts(save) }
    end
  end
end
