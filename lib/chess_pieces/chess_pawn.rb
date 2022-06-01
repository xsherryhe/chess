require_relative './chess_piece.rb'

class Pawn < Piece
  attr_reader :double_step

  def initialize(player_index, starting_position)
    super(player_index)
    @name = 'pawn'
    @position = starting_position
    @vertical_dir = player_index.zero? ? 1 : -1
    @double_step = false
    @base_moves = [[0, @vertical_dir]]
  end

  def move
    new_pos = valid_pos_input(board)
    @double_step = new_pos == double_step_pos
    @position = new_pos
  end

  private

  def legal_next_positions(board)
    legal_positions = base_positions.reject do |pos|
      board.any? { |piece| piece.position == pos }
    end

    legal_positions += diagonal_positions if can_capture(board)
    legal_positions << double_step_pos if in_starting_pos
    legal_positions
  end

  def diagonal_positions
    positions = [-1, 1].map do |horiz_dir|
      [position.first + horiz_dir, position.last + @vertical_dir]
    end
    in_range(positions)
  end

  def double_step_pos
    [position.first, position.last + 2 * @vertical_dir]
  end

  def can_capture(board)
    board.any? do |piece|
      opponent(piece) && diagonal_positions.include?(piece.position)
    end || can_capture_en_passant(board)
  end

  def can_capture_en_passant(board)
    board.any? do |piece|
      piece.is_a(Pawn) && opponent(piece) && piece.double_step &&
        (piece.position.first - position.first).abs == 1
    end
  end

  def in_starting_pos
    position.last == (player_index.zero? ? 1 : 6)
  end
end
