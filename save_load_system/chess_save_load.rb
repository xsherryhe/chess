require_relative './chess_save.rb'

module SaveLoad
  include Save

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
end
