class Piece
  attr_reader :position, :player_index

  def initialize(player_index, starting_position)
    @player_index = player_index
    @position = starting_position
  end

  def move(board)
    @position = valid_pos_input(board)
  end

  private

  def valid_pos_input(board)
    puts "Please enter the square to move the #{@name}."
    new_pos = to_pos(gets.chomp)
    until legal_next_positions(board).include?(new_pos)
      puts "Please enter a square for the #{@name} " \
           'that can be reached with a legal move.'
      new_pos = to_pos(gets.chomp)
    end
    new_pos
  end

  def base_positions
    positions = @base_moves.map do |move|
      [position.first + move.first, position.last + move.last]
    end
    in_range(positions)
  end

  def in_range(positions)
    positions.select do |pos|
      pos.all? { |dir| dir.between?(0, 7) }
    end
  end

  def to_pos(input)
    col, row = input.upcase.chars
    [col.ord - 65, row.to_i - 1]
  end

  def opponent(piece)
    piece.player_index == player_index ^ 1
  end
end
