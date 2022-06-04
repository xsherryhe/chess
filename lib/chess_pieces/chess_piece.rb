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

  def move_instruction
    "Please enter the square to move the #{@name}, "\
    'using the format LETTER + NUMBER (e.g., "A1").'
  end

  def error_message
    "Please enter a square for the #{@name} " \
    'that can be reached with a legal move. ' \
    'Please use the format LETTER + NUMBER (e.g., "A1").'
  end

  def valid_pos_input(board)
    puts move_instruction
    new_pos = to_pos(gets.chomp)
    until legal_next_positions(board).include?(new_pos)
      puts error_message
      new_pos = to_pos(gets.chomp)
    end
    new_pos
  end

  def base_positions
    @base_moves.map do |move|
      [position.first + move.first, position.last + move.last]
    end
  end

  def in_range(positions)
    positions.select do |pos|
      pos.all? { |dir| dir.between?(0, 7) }
    end
  end

  def legal_next_positions(board)
    base_positions.each_slice(7).map do |pos_set|
      pos_set = in_range(pos_set)
      last_index = pos_set.index do |pos|
        board.any? { |piece| piece.position == pos }
      end
      pos_set[0..last_index].reject do |pos|
        board.any? { |piece| player?(piece) && piece.position == pos }
      end
    end.flatten(1)
  end

  def to_pos(input)
    return unless input.length == 2

    col, row = input.upcase.chars
    [col.ord - 65, row.to_i - 1]
  end

  def player?(piece)
    piece.player_index == player_index
  end

  def opponent?(piece)
    piece.player_index == player_index ^ 1
  end
end
