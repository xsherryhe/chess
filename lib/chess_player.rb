require_relative './chess_base.rb'
require_relative './chess_player_input.rb'

class Player
  include BaseMethods

  attr_reader :player_index, :name, :color

  def initialize(player_index, name = nil)
    @player_index = player_index
    @color = %w[White Black][player_index]
    @name = name || select_name
  end

  def to_yaml
    YAML.dump(serialize_vals)
  end

  def self.from_yaml(string)
    player_class, data = YAML.safe_load(string).values
    Module.const_get(player_class).new(data['player_index'], data['name'])
  end

  private

  def serialize_vals
    { 'class' => self.class.name,
      'data' => { 'player_index' => player_index, 'name' => name } }
  end
end

class HumanPlayer < Player
  include PlayerInput

  def select_action(game)
    puts move_instruction(game) +
         "\r\n#{GAME_MENU_INSTRUCTION}"
    action_input(game)
  end

  def select_rook(rooks, game)
    return rooks.first if rooks.size == 1

    puts rook_input_instruction(rooks, game)
    valid_rook_input(rooks)
  end

  def select_promote_class
    puts promote_class_input_instruction
    valid_promote_class_input
  end

  def claim_draw?
    puts "#{name}, do you wish to claim a draw?"
    gets.chomp
  end

  def accept_draw?
    puts "#{name}, do you accept the proposal of draw?"
    gets.chomp
  end

  private

  def select_name
    name_input
  end
end

class ComputerPlayer < Player
  def select_action(game)
    puts 'Computer move:'
    sleep(0.5)
    action = action_options(game).sample
    display_standard_action(action) unless action == 'castle'
    enter_to_continue
    action
  end

  def select_rook(rooks, *)
    rook = rooks.sample
    display_castle_action(rook)
    enter_to_continue
    rook
  end

  def select_promote_class
    promote_class = [Queen, Bishop, Knight, Rook].sample
    sleep(0.5)
    puts "Computer promotes pawn to #{promote_class.name}."
    enter_to_continue
    promote_class
  end

  def claim_draw?
    sleep(0.5)
    'no'
  end

  def accept_draw?
    sleep(0.5)
    puts 'Computer accepts the draw.'
    'yes'
  end

  private

  def select_name
    puts "Computer is the #{color} player."
    'Computer'
  end

  def action_options(game)
    options = game.board.map do |piece|
      next if opponent?(piece)

      next_position = piece.legal_next_positions(game.board, game.move_num + 1)
                           .sample
      [piece, next_position] if next_position
    end.compact
    options << 'castle' if game.can_castle?
    options
  end

  def display_standard_action(action)
    puts [from_pos(action.first.position), from_pos(action.last)].join(' to ')
  end

  def display_castle_action(rook)
    puts "Castle king with rook at #{from_pos(rook.position)}"
  end
end
