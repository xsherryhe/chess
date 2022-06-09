Dir[__dir__ + '/chess_pieces/*.rb'].sort.each { |file| require file }
require_relative './chess_player.rb'
require_relative './chess_display_board.rb'

class Game
  include BoardDisplay

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
      take_turn
      #evaluate_game
    end
  end

  private

  def take_turn
    display_board
    @move_num += 1
    player = @players[@curr_player_index]
    pieces = @board.select { |piece| player?(piece) }
    target_piece = valid_piece_input(player, pieces)
    target_piece.move(@board, @move_num)
    @board.delete_if { |piece| opponent?(piece) && piece.position == target_piece.position }
    @curr_player_index ^= 1
  end

  def valid_piece_input(player, pieces)
    puts select_piece_instruction(player)
    loop do
      piece_pos = to_pos(gets.chomp)
      target_piece = pieces.find { |piece| piece.position == piece_pos }
      if target_piece && !target_piece.legal_next_positions(@board, @move_num).empty?
        return target_piece
      end

      puts select_piece_error_message(target_piece, piece_pos)
    end
  end

  def select_piece_instruction(player)
    player.name + ', ' + select_piece_message
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
    'please enter the square of the piece that you wish to move, ' \
    'using the format LETTER + NUMBER (e.g., "A1").'
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

  def to_pos(input)
    return unless input.length == 2

    col, row = input.upcase.chars
    pos = [col.ord - 65, row.to_i - 1]
    pos.all? { |dir| dir.between?(0, 7) } ? pos : nil
  end

  def player?(piece)
    piece.player_index == @curr_player_index
  end

  def opponent?(piece)
    piece.player_index == @curr_player_index ^ 1
  end
end

game = Game.new
game.play
