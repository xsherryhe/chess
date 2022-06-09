module BoardDisplay
  private

  def display_board
    text_board = displayed_board.map.with_index do |row, i|
      "#{i + 1}#{row.join}"
    end.reverse << displayed_board_letters
    puts "\r\n" + text_board.map { |line| '     ' + line }.join("\r\n") + "\r\n"
  end

  def displayed_board
    displayed_board = Array.new(8) do |i|
      Array.new(8) do |j|
        i.even? == j.even? ? "\e[47m   \e[0m" : "\e[103m   \e[0m"
      end
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
        else "\e[103m #{piece.symbol} \e[0m"
        end
    end
  end

  def displayed_board_letters
    ' ' + ('A'..'H').map { |lett| " #{lett} " }.join
  end
end
