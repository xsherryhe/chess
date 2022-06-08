Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }

class Game
  def initialize
    #@players = [0, 1].map { Player.new(player_index) }
    @board = []
    insert_starting_board
    @move_num = 0
  end

  def display_board
    text_board = displayed_board.map.with_index do |row, i|
      "#{i + 1} |#{row.join}|"
    end.reverse
    text_board.unshift(displayed_board_edge)
    text_board += displayed_board_bottom
    puts text_board.map { |line| '     ' + line }.join("\r\n")
  end

  private

  def insert_starting_board
    [0, 1].each do |player_index|
      { Rook => [0, 7], Knight => [1, 6], Bishop => [2, 5],
        Queen => [3], King => [4] }.each do |piece_class, horiz_dirs|
          insert_non_pawn_starting(horiz_dirs, piece_class, player_index)
        end
      insert_pawn_starting(player_index)
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

  def displayed_board
    displayed_board = Array.new(8) do |i|
      Array.new(8) { |j| i.even? == j.even? ? "\e[47m   \e[0m" : '   ' }
    end

    fill_displayed_board(displayed_board)
    displayed_board
  end

  def fill_displayed_board(displayed_board)
    @board.each do |piece|
      col, row = piece.position
      displayed_board[row][col] =
        if displayed_board[row][col].include?("\e[47m")
          "\e[47m #{piece.symbol} \e[0m"
        else " #{piece.symbol} "
        end
    end
  end

  def displayed_board_edge
    ' ' * 3 + '-' * 24
  end

  def displayed_board_bottom
    [displayed_board_edge, ' ' * 3 + ('A'..'H').map { |lett| " #{lett} " }.join]
  end
end

game = Game.new
game.display_board
