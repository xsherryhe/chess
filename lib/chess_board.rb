module Board
  def display_board
    system 'clear'
    puts "\r\n#{displayed_board.map { |line| '     ' + line }.join("\r\n")}\r\n"
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
    displayed_squares.map.with_index do |row, i|
      "#{i + 1}#{row.join}"
    end.reverse << displayed_board_letters
  end

  def displayed_squares
    displayed_squares = Array.new(8) do |i|
      Array.new(8) do |j|
        i.even? == j.even? ? "\e[47m   \e[0m" : "\e[103m   \e[0m"
      end
    end

    fill_displayed_squares(displayed_squares)
    displayed_squares
  end

  def fill_displayed_squares(displayed_squares)
    board.each do |piece|
      col, row = piece.position
      displayed_squares[row][col] =
        if displayed_squares[row][col].include?("\e[47m")
          "\e[47m\e[30m #{piece.symbol} \e[0m\e[0m"
        else "\e[103m\e[30m #{piece.symbol} \e[0m\e[0m"
        end
    end
  end

  def displayed_board_letters
    ' ' + ('A'..'H').map { |lett| " #{lett} " }.join
  end
end
