require_relative './chess_piece.rb'

class Pawn < Piece
  attr_reader :double_step

  def initialize(player_index, starting_position)
    super
    @name = 'pawn'
    @vertical_dir = player_index.zero? ? 1 : -1
    @double_step = false
    @base_moves = [[0, @vertical_dir]]
  end

  def move(board, move_num)
    update_next_positions(board, move_num)
    new_pos = valid_pos_input
    @double_step = move_num if new_pos == double_step_pos
    @position = new_pos
  end

  def next_positions(board, move_num)
    positions = in_range(base_positions).reject do |pos|
      board.any? { |piece| piece.position == pos }
    end

    diagonal_positions.each do |diag_pos|
      positions << diag_pos if can_capture?(move_num, diag_pos, board)
    end
    positions << double_step_pos if in_starting_pos?
    positions
  end

  private

  def diagonal_positions
    positions = [-1, 1].map do |horiz_dir|
      [position.first + horiz_dir, position.last + @vertical_dir]
    end
    in_range(positions)
  end

  def double_step_pos
    [position.first, position.last + 2 * @vertical_dir]
  end

  def can_capture?(move_num, diag_pos, board)
    board.any? do |piece|
      opponent?(piece) &&
        (piece.position == diag_pos ||
         can_capture_en_passant?(move_num, piece, diag_pos))
    end
  end

  def can_capture_en_passant?(move_num, piece, diag_pos)
    piece.is_a?(Pawn) &&
      piece.double_step == move_num - 1 &&
      piece.position.first == diag_pos.first &&
      piece.position.last == position.last
  end

  def in_starting_pos?
    position.last == (player_index.zero? ? 1 : 6)
  end

  # TODO: Promotion
end
