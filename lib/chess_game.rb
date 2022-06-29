require 'yaml'
Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }
require_relative './chess_base.rb'
require_relative './chess_player.rb'
require_relative './chess_board.rb'
require_relative './chess_castle.rb'
require_relative './chess_promotion.rb'
require_relative './chess_game_menu.rb'
require_relative './chess_game_conditions.rb'
require_relative './chess_game_serialization.rb'

class Game
  include BaseMethods
  include Board
  include Castle
  include Promotion
  include GameMenu
  include GameConditions
  include GameSerialization

  def initialize(custom_setup = false)
    return if custom_setup

    @players = [0, 1].map { |player_ind| Player.new(player_ind) }
    @curr_player_index = 0
    @board = []
    insert_starting_board
    @move_num = 0
    @idle_moves = 0
    @history = []
    update_history
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
    puts "#{curr_player.name}: #{move_instruction}"
    puts game_menu_instruction
    action = valid_input
    if action.is_a?(String)
      return game_menu if action.downcase == 'menu'
      return take_turn(player_king, 'castle') if action.downcase == 'castle'
    end

    take_turn(*action)
  end

  private

  def curr_player
    @players[@curr_player_index]
  end

  def curr_opponent
    @players[@curr_player_index ^ 1]
  end

  def valid_input
    loop do
      input = gets.chomp
      return input if special_inputs.include?(input.downcase)

      piece_pos, goal_pos = input.split(/ ?to ?/i)
                                 .map { |pos_input| to_pos(pos_input) }
      target_piece = find_player_piece(piece_pos)
      return [target_piece, goal_pos] if valid_move?(target_piece, goal_pos)

      puts input_error_message(target_piece, piece_pos, goal_pos)
    end
  end

  def special_inputs
    rooks_to_castle.empty? ? %w[menu] : %w[menu castle]
  end

  def find_player_piece(pos)
    @board.find { |piece| player?(piece) && piece.position == pos }
  end

  def valid_move?(target_piece, goal_pos)
    target_piece&.legal_next_positions(@board, @move_num + 1)
                &.include?(goal_pos)
  end

  def take_turn(target_piece, goal_pos)
    @move_num += 1
    goal_pos == 'castle' ? castle : target_piece.move(goal_pos, @move_num)
    capture_ind = index_to_capture(target_piece)
    @idle_moves = capture_ind || target_piece.is_a?(Pawn) ? 0 : @idle_moves + 1
    capture_piece(capture_ind)
    promote(target_piece) if target_piece.is_a?(Pawn) && target_piece.promoting
    @curr_player_index ^= 1
    update_history
  end

  def input_error_message(target_piece, piece_pos, goal_pos)
    both_valid_pos = piece_pos && goal_pos
    error_message =
      if !both_valid_pos then 'Invalid input!'
      elsif !target_piece then "You don't have a piece on that square!"
      elsif target_piece.illegal_check_next_positions.include?(goal_pos)
        'Illegal move! This move would leave your king in check.'
      else 'Illegal move!'
      end
    error_message + "\r\n#{move_instruction}" +
      (both_valid_pos ? '' : " #{game_menu_instruction}")
  end

  def move_instruction
    'Please enter the move you wish to make' +
      (if @move_num < 2
         ', using the format "(LETTER + NUMBER) to (LETTER + NUMBER)". ' \
         'For example, "A2 to A3".'
       else '.'
       end) +
      (rooks_to_castle.empty? ? '' : "\r\n#{castle_instruction}")
  end

  def update_history
    @history << YAML.dump('curr_player_index' => @curr_player_index,
                          'board' => @board.map(&:to_yaml).sort)
  end
end
