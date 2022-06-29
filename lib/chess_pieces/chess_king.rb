require_relative './chess_piece.rb'

class King < Piece
  attr_reader :moved

  def initialize(player_index, starting_position)
    super
    @name = 'king'
    @symbol = ["\u2654", "\u265A"][player_index]
    @base_moves = ([-1, 0, 1].product([-1, 0, 1]) - [[0, 0]])
    @moved = false
  end

  def move(goal_pos)
    super
    @moved = true
  end

  def next_positions(board, *)
    in_range(base_positions).reject do |pos|
      board.any? { |piece| player?(piece) && piece.position == pos }
    end
  end

  def checked?(pos, board, move_num)
    board.any? do |piece|
      opponent?(piece) && piece.next_positions(board, move_num).include?(pos)
    end
  end

  private

  def serialize_vals
    super.merge('data' => { 'moved' => @moved }) do |_, sup_d, new_d|
      sup_d.merge(new_d)
    end
  end
end
