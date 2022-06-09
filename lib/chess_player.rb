class Player
  attr_reader :player_index, :name, :color

  def initialize(player_index)
    @player_index = player_index
    @color = %w[White Black][player_index]
    puts "#{color} player, please enter your name."
    @name = gets.chomp
  end
end
