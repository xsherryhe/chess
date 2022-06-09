class Player
  attr_reader :player_index, :name

  def initialize(player_index)
    @player_index = player_index
    @color = %w[white black][player_index]
    puts "#{@color.capitalize} player, please enter your name."
    @name = gets.chomp
  end
end
