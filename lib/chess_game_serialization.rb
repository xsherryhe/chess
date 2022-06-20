module GameSerialization
  private

  def to_yaml
    data = instance_variables.each_with_object({}) do |var, obj|
      val = instance_variable_get(var)
      obj[var] = %i[@players @board].include?(var) ? val.map(&:to_yaml) : val
    end

    YAML.dump(data)
  end

  def from_yaml(file)
    YAML.load_file(file).each do |var, val|
      val = players_from_yaml(val) if var == :@players
      val = board_from_yaml(val) if var == :@board
      instance_variable_set(var, val)
    end
  end

  def players_from_yaml(player_strings)
    player_strings.map do |player_string|
      data = YAML.safe_load(player_string)
      Player.new(data[:@player_index], data[:@player_name])
    end
  end

  def board_from_yaml(piece_strings)
    piece_strings.map do |piece_string|
      piece_class, data = YAML.safe_load(piece_string).values
      piece = piece_class.new(data[:@player_index], data[:@position])
      data.each do |piece_var, piece_val|
        piece.instance_variable_set(piece_var, piece_val)
      end
    end
  end
end
