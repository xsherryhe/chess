require_relative './chess_piece.rb'

class Pawn < Piece
  attr_reader :double_step, :en_passant, :promoting

  def initialize(player_index, starting_position)
    super
    @name = 'pawn'
    @symbol = ["\u2659", "\u265F"][player_index]
    @vertical_dir = [1, -1][player_index]
    @double_step = false
    @en_passant = false
    @base_moves = [[0, @vertical_dir]]
  end

  def move(goal_pos, move_num)
    @double_step = move_num if goal_pos == double_step_pos
    @promoting = true if goal_pos.last == 7 * (player_index ^ 1)
    super
  end

  def next_positions(board, move_num)
    positions = in_range(base_positions)
    positions << double_step_pos if can_double_step?(board)
    positions.reject! do |pos|
      board.any? { |piece| piece.position == pos }
    end
    positions + capture_positions(board, move_num)
  end

  private

  def serialize_vals
    super.merge('data' => { 'double_step' => @double_step,
                            'en_passant' => @en_passant }) do |_, sup_d, new_d|
      sup_d.merge(new_d)
    end
  end

  def capture_positions(board, move_num)
    positions = []
    update_en_passant(board, move_num)
    positions << en_passant.first if en_passant
    diagonal_positions.each do |diag_pos|
      positions << diag_pos if can_capture?(diag_pos, board)
    end
    positions
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

  def can_capture?(diag_pos, board)
    board.any? { |piece| opponent?(piece) && piece.position == diag_pos }
  end

  def update_en_passant(board, move_num)
    @en_passant = false
    diagonal_positions.each do |diag_pos|
      en_passant_piece = board.find do |piece|
        can_capture_en_passant?(piece, move_num, diag_pos)
      end
      @en_passant = [diag_pos, en_passant_piece.position] if en_passant_piece
    end
  end

  def can_capture_en_passant?(piece, move_num, diag_pos)
    piece.is_a?(Pawn) &&
      opponent?(piece) &&
      piece.double_step == move_num - 1 &&
      piece.position.first == diag_pos.first &&
      piece.position.last == position.last
  end

  def can_double_step?(board)
    position.last == [1, 6][player_index] &&
      board.none? do |piece|
        piece.position == [position.first, [2, 5][player_index]]
      end
  end
end
