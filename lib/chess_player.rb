class Player
  attr_reader :player_index, :name, :color

  def initialize(player_index, name = nil)
    @player_index = player_index
    @color = %w[White Black][player_index]
    @name = name || name_input
  end

  def to_yaml
    YAML.dump('player_index' => @player_index, 'name' => @name)
  end

  def self.from_yaml(string)
    data = YAML.safe_load(string)
    new(data['player_index'], data['name'])
  end

  private

  def name_input
    puts "#{color} player, please enter your name."
    gets.chomp
  end
end
