class Piece
  attr_reader :position, :player_index

  def initialize(player_index)
    @player_index = player_index
  end

  def move
    @position = valid_pos_input(board)
  end

  private

  def valid_pos_input(board)
    until legal_next_pos(board).include?(new_pos)
      puts "Please enter a position for the #{@name} " \
           'that can be reached with a legal move.'
      new_pos = to_pos(gets.chomp)
    end
    new_pos
  end

  def base_pos
    @base_moves.filter_map do |move|
      new_pos = [position.first + move.first, position.last + move.last]
      new_pos if new_pos.all? { |dir| dir.between?(0, 7) }
    end
  end

  def to_pos(input)
    col, row = input.upcase.chars
    [col.ord - 65, row.to_i - 1]
  end
end
