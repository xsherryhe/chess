module PlayerInput
  CASTLE_INSTRUCTION = 'Castling is also available. ' \
                       'Enter the word CASTLE to make a castling move.'.freeze
  GAME_MENU_INSTRUCTION = '(Or enter the word MENU to view other game options.)'
                          .freeze

  private

  def name_input
    puts "#{color} player, please enter your name."
    gets.chomp
  end

  def move_instruction(game)
    "#{name}: Please enter the move you wish to make" +
      (if game.move_num < 2
         ', using the format "(LETTER + NUMBER) to (LETTER + NUMBER)". ' \
         'For example, "A2 to A3".'
       else '.'
       end) +
      (game.can_castle? ? "\r\n#{CASTLE_INSTRUCTION}" : '')
  end

  def action_input(game)
    loop do
      input = gets.chomp
      return input if special_inputs(game).include?(input.downcase)

      piece_pos, goal_pos = input.split(/ ?to ?/i)
                                 .map { |pos_input| to_pos(pos_input) }
      target_piece = find_player_piece(game, piece_pos)
      return [target_piece, goal_pos] if can_move?(game, target_piece, goal_pos)

      puts input_error_message(game, target_piece, piece_pos, goal_pos)
    end
  end

  def special_inputs(game)
    game.can_castle? ? %w[menu castle] : %w[menu]
  end

  def find_player_piece(game, pos)
    game.board.find { |piece| player?(piece) && piece.position == pos }
  end

  def can_move?(game, target_piece, goal_pos)
    target_piece&.legal_next_positions(game.board, game.move_num + 1)
                &.include?(goal_pos)
  end

  def input_error_message(game, target_piece, piece_pos, goal_pos)
    both_valid_pos = piece_pos && goal_pos
    error_message =
      if !both_valid_pos then 'Invalid input!'
      elsif !target_piece then "You don't have a piece on that square!"
      elsif target_piece.illegal_check_next_positions.include?(goal_pos)
        'Illegal move! This move would leave your king in check.'
      else 'Illegal move!'
      end
    error_message + "\r\n#{move_instruction(game)}" +
      (both_valid_pos ? '' : " #{GAME_MENU_INSTRUCTION}")
  end

  def valid_rook_input(rooks)
    loop do
      rook_position = to_pos(gets.chomp)
      chosen_rook = rooks.find { |rook| rook.position == rook_position }
      return chosen_rook if chosen_rook

      puts rook_error_message
    end
  end

  def rook_input_instruction(rooks, game)
    valid_rook_display(rooks) +
      "\r\nPlease enter the square of the rook " \
      'that you would like your king to castle with' +
      (game.move_num < 2 ? ', using the format LETTER + NUMBER.' : '.')
  end

  def valid_rook_display(rooks)
    'Your king can castle with the following rooks at: ' +
      rooks.map { |rook| from_pos(rook.position) }.join(', ')
  end

  def rook_error_message
    'Invalid square! Please enter the square of a valid rook to castle with. ' \
    'Please use the format LETTER + NUMBER (e.g., "A1").'
  end

  def valid_promote_class_input
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
