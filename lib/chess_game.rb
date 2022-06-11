Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }
require_relative './chess_base.rb'
require_relative './chess_player.rb'
require_relative './chess_board.rb'
require_relative './chess_game_menu.rb'
require_relative './chess_game_conditions.rb'

class Game
  include BaseMethods
  include Board
  include GameMenu
  include GameConditions

  def initialize
    puts "Let's play chess!"
    @players = [0, 1].map { |player_index| Player.new(player_index) }
    @curr_player_index = 0
    @board = []
    insert_starting_board
    @move_num = 0
  end

  def play
    until @game_over
      display_board
      display_check_state
      player_action
      display_mate_state
    end
  end

  def player_action
    player = @players[@curr_player_index]
    pieces = @board.select { |piece| player?(piece) }
    action = valid_input(player, pieces)
    return game_menu(player) if action =~ /^menu$/i

    take_turn(action)
  end

  private

  def valid_input(player, pieces)
    puts select_piece_instruction(player) + game_menu_instruction

    loop do
      input = gets.chomp
      return input if input =~ /^menu$/i

      piece_pos = to_pos(input)
      target_piece = pieces.find { |piece| piece.position == piece_pos }
      return target_piece if valid_piece?(target_piece)

      puts select_piece_error_message(target_piece, piece_pos)
    end
  end

  def valid_piece?(target_piece)
    target_piece && !target_piece.legal_next_positions(@board, @move_num).empty?
  end

  def take_turn(target_piece)
    @move_num += 1
    target_piece.move(@board, @move_num)
    capture_pieces(target_piece)
    @curr_player_index ^= 1
  end

  def select_piece_instruction(player)
    player.name + ', ' + select_piece_message
  end

  def game_menu_instruction
    ' (Or enter the word MENU to view other game options.)'
  end

  def select_piece_error_message(target_piece, piece_pos)
    error_message =
      if target_piece
        'There are no legal moves for this piece. ' \
        'Please select a different piece to move. '
      elsif piece_pos
        "You don't have a piece on that square! "
      else 'Invalid input! '
      end
    error_message + select_piece_message.capitalize
  end

  def select_piece_message
    'please enter the square of the piece that you wish to move' +
      (@move_num < 2 ? ', using the format LETTER + NUMBER.' : '.')
  end

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
end

game = Game.new
game.play
