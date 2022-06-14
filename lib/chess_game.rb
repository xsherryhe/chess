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
    action =~ /^menu$/i ? game_menu(player) : take_turn(action)
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

      puts input_error_message(target_piece, piece_pos)
    end
  end

  def valid_piece?(target_piece)
    target_piece && !target_piece.legal_next_positions(@board, @move_num).empty?
  end

  def take_turn(target_piece)
    @move_num += 1
    target_piece.move(@board, @move_num)
    capture_pieces(target_piece)
    promote(target_piece) if target_piece.is_a?(Pawn) && target_piece.promoting
    @curr_player_index ^= 1
  end

  def select_piece_instruction(player)
    player.name + ', ' + select_piece_message
  end

  def input_error_message(target_piece, piece_pos)
    error_message =
      if target_piece
        'There are no legal moves for this piece. ' \
        'Please select a different piece to move. '
      elsif piece_pos
        "You don't have a piece on that square! "
      else 'Invalid input! '
      end
    error_message + select_piece_message.capitalize +
      (target_piece || piece_pos ? '' : game_menu_instruction)
  end

  def select_piece_message
    'please enter the square of the piece that you wish to move' +
      (@move_num < 2 ? ', using the format LETTER + NUMBER.' : '.')
  end

  def promote(pawn)
    display_board
    puts "#{@players[@curr_player_index].name}, your pawn must promote."
    @board << valid_promote_class_input.new(@curr_player_index, pawn.position)
    @board.delete(pawn)
  end

  def valid_promote_class_input
    puts promote_class_input_instruction
    loop do
      class_index = %w[queen bishop knight rook].index(gets.chomp.downcase)
      return [Queen, Bishop, Knight, Rook][class_index] if class_index

      puts 'Invalid input! ' + promote_class_input_instruction
    end
  end

  def promote_class_input_instruction
    "Please enter the piece type to promote your pawn to:\r\n" \
    '  ' + %w[QUEEN BISHOP KNIGHT ROOK]
           .map.with_index(1) { |name, i| "#{i}. #{name}" }.join("\r\n  ")
  end
end
