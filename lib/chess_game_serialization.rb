module GameSerialization
  def to_yaml
    data = instance_variables.each_with_object({}) do |var, obj|
      val = instance_variable_get(var)
      key = var.to_s.delete('@')
      obj[key] = %w[players board].include?(key) ? val.map(&:to_yaml) : val
    end

    YAML.dump(data)
  end

  def self.included(base)
    base.extend FromYaml
  end

  module FromYaml
    def from_yaml(file)
      game = new(true)
      game.update_from_yaml(file)
      game
    end
  end

  def update_from_yaml(file)
    YAML.load_file(file).each do |key, val|
      val.map! { |string| Player.from_yaml(string) } if key == 'players'
      val.map! { |string| Piece.from_yaml(string) } if key == 'board'
      var = ('@' + key).to_sym
      instance_variable_set(var, val)
    end
  end
end
