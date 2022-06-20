require 'yaml'
Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }
require_relative './chess_base.rb'
require_relative './chess_player.rb'
require_relative './chess_board.rb'
require_relative './chess_promotion.rb'
require_relative './chess_game_menu.rb'
require_relative './chess_game_conditions.rb'
require_relative './chess_game_serialization.rb'

class Game
  include BaseMethods
  include Board
  include Promotion
  include GameMenu
  include GameConditions
  include GameSerialization

  def initialize(file = nil)
    file ? from_yaml(file) : start_game_setup
  end

  def play
    until @game_over
      display_board
      display_check_state
      player_action
      display_draw_claim_state
      display_mate_state
    end
  end

  def player_action
    pieces = @board.select { |piece| player?(piece) }
    action = valid_input(pieces)
    action =~ /^menu$/i ? game_menu : take_turn(action)
  end

  private

  def start_game_setup
    @players = [0, 1].map { |player_ind| Player.new(player_ind) }
    @curr_player_index = 0
    @board = []
    insert_starting_board
    @move_num = 0
    @idle_moves = 0
    @history = []
    update_history
  end

  def curr_player
    @players[@curr_player_index]
  end

  def curr_opponent
    @players[@curr_player_index ^ 1]
  end

  def valid_input(pieces)
    puts select_piece_instruction + game_menu_instruction

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
    capture_ind = index_to_capture(target_piece)
    @idle_moves = capture_ind || target_piece.is_a?(Pawn) ? 0 : @idle_moves + 1
    capture_piece(capture_ind)
    promote(target_piece) if target_piece.is_a?(Pawn) && target_piece.promoting
    @curr_player_index ^= 1
    update_history
  end

  def select_piece_instruction
    curr_player.name + ', ' + select_piece_message
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

  def update_history
    @history << YAML.dump(:@curr_player_index => @curr_player_index,
                          :@board => @board.map(&:to_yaml).sort)
  end
end
