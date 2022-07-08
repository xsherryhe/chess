require_relative './chess_enter.rb'

module Menu
  include PressEnter

  def access_menu
    until @menu_done
      system 'clear'
      puts menu_options
      display_invalid_input if @invalid_input
      select_menu_option
    end
    @menu_done = false
  end

  def display_information
    puts "\r\n" + chess_introduction + "\r\n"
    enter_to_continue
  end

  def display_game_instructions
    puts "\r\n" + chess_introduction + "\r\n\r\n" + pos_input_instruction
    enter_to_continue
  end

  def chess_introduction
    'Chess is a board game with two players, ' \
    "in which the goal is to checkmate the other player.\r\n" \
    'For information about the rules of the game, ' \
    'please visit http://www.chessvariants.org/d.chess/chess.html or ' \
    'https://en.wikipedia.org/wiki/Chess.'
  end

  def pos_input_instruction
    'In this program, all squares and positions should be entered ' \
    "using the format LETTER + NUMBER.\r\n" \
    'LETTER refers to the columns of the chess board ' \
    "and runs from A to H.\r\n" \
    'NUMBER refers to the rows of the chess board ' \
    "and runs from 1 to 8.\r\n" \
    "So, examples of valid inputs are:\r\n" \
    "     A1 F6 G8 H4\r\n" \
    'Inputs that do not follow this format will not be accepted.'
  end

  def display_invalid_input
    puts 'Invalid input!'
    @invalid_input = false
  end
end
