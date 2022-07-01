require 'yaml'
Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }
require_relative './chess_base.rb'
require_relative './chess_player.rb'
require_relative './chess_board.rb'
require_relative './chess_castle.rb'
require_relative './chess_game_menu.rb'
require_relative './chess_game_conditions.rb'
require_relative './chess_game_serialization.rb'

class Game
  include BaseMethods
  include Board
  include Castle
  include GameMenu
  include GameConditions
  include GameSerialization

  attr_reader :board, :move_num

  def initialize(custom_setup = false, has_computer_player = false)
    return if custom_setup

    @players = players(has_computer_player)
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
    action = curr_player.select_action(self)

    if action.is_a?(String)
      return game_menu if action.downcase == 'menu'
      return take_turn(player_king, 'castle') if action.downcase == 'castle'
    end

    take_turn(*action)
  end

  private

  def players(has_computer_player)
    if has_computer_player
      computer_ind = rand(2)
      human_ind = computer_ind ^ 1
      [[ComputerPlayer, computer_ind],
       [HumanPlayer, human_ind]].map do |player, player_ind|
         player.new(player_ind)
       end.sort_by(&:player_index)
    else [0, 1].map { |player_ind| HumanPlayer.new(player_ind) }
    end
  end

  def curr_player
    @players[@curr_player_index]
  end

  def curr_opponent
    @players[@curr_player_index ^ 1]
  end

  def take_turn(target_piece, goal_pos)
    @move_num += 1
    goal_pos == 'castle' ? castle : target_piece.move(goal_pos, move_num)
    capture_ind = index_to_capture(target_piece)
    @idle_moves = capture_ind || target_piece.is_a?(Pawn) ? 0 : @idle_moves + 1
    capture_piece(capture_ind)
    promote(target_piece) if target_piece.is_a?(Pawn) && target_piece.promoting
    @curr_player_index ^= 1
    update_history
  end

  def promote(pawn)
    display_board
    puts "#{curr_player.name}, your pawn must promote."
    @board << curr_player.select_promote_class
                         .new(@curr_player_index, pawn.position)
    @board.delete(pawn)
  end

  def update_history
    @history << YAML.dump('curr_player_index' => @curr_player_index,
                          'board' => board.map(&:to_yaml).sort)
  end
end
