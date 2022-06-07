Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }

class Game
  def initialize
    #@players = [0, 1].map { Player.new(player_index) }
    @board = []
    insert_starting_board
    @move_num = 0
  end

  def display_board
    displayed_board = Array.new(8) do |i|
      Array.new(8) { |j| i.even? == j.even? ? '|||' : '   ' }
    end

    row_barrier = "\r\n+#{(['---'] * 8).join('+')}+\r\n"
    puts row_barrier +
         displayed_board.reverse
                        .map { |row| "|#{row.join('|')}|" }
                        .join(row_barrier) +
         row_barrier
  end

  private

  def insert_starting_board
    [0, 1].each do |player_index|
      { Rook => [0, 7], Knight => [1, 6], Bishop => [2, 5],
        Queen => [3], King => [4] }.each do |piece_class, horiz_dirs|
          insert_non_pawn_starting(horiz_dirs, piece_class, player_index)
        end
    end
  end

  def insert_non_pawn_starting(horiz_dirs, piece_class, player_index)
    horiz_dirs.each do |horiz_dir|
      @board << piece_class.new(player_index, [horiz_dir, 7 * player_index])
    end
  end

  def insert_pawn_starting(player_index)
    (0..7).each do |horiz_dir|
      @board << Pawn.new(player_index, [horiz_dir, [1, 6][player_index]])
    end
  end
end

game = Game.new
game.display_board
