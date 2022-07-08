require_relative '../chess_enter.rb'

module SaveLoadBaseMethods
  include PressEnter

  private

  def save_dir
    "#{File.expand_path('../..', __dir__)}/saves"
  end

  def save_record
    "#{save_dir}/save_record.txt"
  end

  def existing_save?(name)
    File.readlines(save_record).include?(name + "\n")
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
    record.delete(name + "\n")
    record << name if add
    File.open(save_record, 'w') do |record_file|
      record.each { |save| record_file.puts(save) }
    end
  end
end
