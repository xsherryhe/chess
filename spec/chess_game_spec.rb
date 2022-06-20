require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }
  let(:board) { game.instance_variable_get(:@board) }

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
  end

  describe '#initialize' do
    before do
      allow(game).to receive(:puts)
    end

    it 'sets up starting board with correct number of pieces for each side' do
      side_count = board.partition { |piece| piece.player_index.zero? }.map(&:size)
      expect(side_count).to eq([16, 16])
    end

    it 'sets up starting board with correct number of piece types' do
      piece_counts = [Pawn, Rook, Knight, Bishop, Queen, King].map do |type|
        board.count { |piece| piece.class == type }
      end
      expect(piece_counts).to eq([16, 4, 4, 4, 2, 2])
    end

    it 'sets up starting board with correct positions' do
      correct_positions = [0, 1, 6, 7].map do |vert_dir|
        (0..7).map { |horiz_dir| [horiz_dir, vert_dir] }
      end.flatten(1).sort
      positions = board.map(&:position).sort
      expect(positions).to eq(correct_positions)
    end
  end

  describe '#play' do
    before do
      allow(game).to receive(:display_board)
      allow(game).to receive(:display_check_state)
      allow(game).to receive(:player_action)
      allow(game).to receive(:display_draw_claim_state)
    end

    context 'when the game is over' do
      it 'does not execute the loop' do
        allow(game).to receive(:display_mate_state)
        game.instance_variable_set(:@game_over, true)
        expect(game).not_to receive(:display_board)
        expect(game).not_to receive(:display_check_state)
        expect(game).not_to receive(:player_action)
        expect(game).not_to receive(:display_mate_state)
        game.play
      end
    end

    context 'when the game is over after a random number of loops' do
      10.times do
        it 'executes the loop the corresponding number of times' do
          loops = rand(1..100)
          call_count = 0
          allow(game).to receive(:display_mate_state) do
            call_count += 1
            game.instance_variable_set(:@game_over, true) if call_count == loops
          end
          expect(game).to receive(:display_board).exactly(loops).times
          expect(game).to receive(:display_check_state).exactly(loops).times
          expect(game).to receive(:player_action).exactly(loops).times
          expect(game).to receive(:display_mate_state).exactly(loops).times
          game.play
        end
      end
    end
  end

  describe '#display_check_state' do
    let(:checked_player_index) { rand(2) }
    let(:checked_player) { [white_player, black_player][checked_player_index] }
    let(:checking_player) { [white_player, black_player][checked_player_index ^ 1] }
    let(:king_to_check) { instance_double(King, player_index: checked_player_index, position: Array.new(2) { rand(8) }) }
    let(:check_message_reg) { Regexp.new("#{checking_player.color} gives check to #{checked_player.color}.") }

    before do
      allow(King).to receive(:new).with(checked_player_index, anything).and_return(king_to_check)
      allow(king_to_check).to receive(:is_a?).with(King).and_return(true)
      allow(king_to_check).to receive(:to_yaml).and_return('')
      allow(King).to receive(:new).with(checked_player_index ^ 1, anything).and_call_original
      allow(game).to receive(:puts)
      allow(game).to receive(:gets).and_return('')
      game.instance_variable_set(:@curr_player_index, checked_player_index)
    end

    context 'when a player checks their opponent' do
      10.times do
        it 'outputs a check message' do
          allow(king_to_check).to receive(:checked?).and_return(true)
          expect(game).to receive(:puts).with(check_message_reg)
          game.display_check_state
        end
      end
    end

    context 'when a player does not check their opponent' do
      10.times do
        it 'does not output a check message' do
          allow(king_to_check).to receive(:checked?).and_return(false)
          expect(game).not_to receive(:puts).with(check_message_reg)
          game.display_check_state
        end
      end
    end
  end

  describe '#display_draw_claim_state' do
    let(:game_history_position) do
      Array.new(rand(50)) { (('A'..'Z').to_a + ('a'..'z').to_a).sample }.join
    end

    before do
      allow(game).to receive(:puts)
      game.instance_variable_set(:@history, [game_history_position] * rand(5))
      game.instance_variable_set(:@idle_moves, rand(200))
      allow(game).to receive(:gets).and_return(%w[YES yes Y y].sample)
    end

    context 'when the game history includes a repetition of positions at least three times' do
      before do
        game.instance_variable_set(:@history, [game_history_position] * rand(3..30))
      end

      10.times do
        it 'displays a repetition of positions message and prompts the user to claim a draw' do
          expect(game).to receive(:puts).with(/The same position with the same player to move has been repeated at least 3 times in the game/)
          expect(game).to receive(:puts).with(/do you wish to claim a draw\?/)
          game.display_draw_claim_state
        end
      end

      context 'when the user confirms that they wish to claim a draw' do
        10.times do
          it 'outputs a draw message' do
            expect(game).to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'ends the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).to be true
          end
        end
      end

      context 'when the user does not confirm that they wish to claim a draw' do
        before do
          allow(game).to receive(:gets).and_return(['n', 'N', 'no', 'NO', 'yesterday', ''].sample)
        end

        10.times do
          it 'does not output a draw message' do
            expect(game).not_to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'does not end the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).not_to be true
          end
        end
      end
    end

    context 'when there have been 50 moves by both players without a piece captured or pawn move' do
      before do
        game.instance_variable_set(:@idle_moves, rand(100..200))
      end

      10.times do
        it 'displays a 50 moves message and prompts the user to claim a draw' do
          expect(game).to receive(:puts).with(/there have been 50 consecutive moves of both players without any piece taken or any pawn move/i)
          expect(game).to receive(:puts).with(/do you wish to claim a draw\?/)
          game.display_draw_claim_state
        end
      end

      context 'when the user confirms that they wish to claim a draw' do
        10.times do
          it 'outputs a draw message' do
            expect(game).to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'ends the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).to be true
          end
        end
      end

      context 'when the user does not confirm that they wish to claim a draw' do
        before do
          allow(game).to receive(:gets).and_return(['n', 'N', 'no', 'NO', 'yesterday', ''].sample)
        end

        10.times do
          it 'does not output a draw message' do
            expect(game).not_to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'does not end the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).not_to be true
          end
        end
      end
    end

    context 'when no conditions are fulfilled that allow a draw claim' do
      before do
        game.instance_variable_set(:@history, [game_history_position] * rand(3))
        game.instance_variable_set(:@idle_moves, rand(100))
      end

      10.times do
        it 'does not prompt the user to claim a draw' do
          expect(game).not_to receive(:puts).with(/do you wish to claim a draw\?/)
          game.display_draw_claim_state
        end
      end
    end
  end

  describe '#display_mate_state' do
    let(:mated_player_index) { rand(2) }
    let(:mated_player) { [white_player, black_player][mated_player_index] }
    let(:mating_player) { [white_player, black_player][mated_player_index ^ 1] }
    let(:king_to_mate) { instance_double(King, player_index: mated_player_index, position: Array.new(2) { rand(8) }) }

    before do
      allow(King).to receive(:new).with(mated_player_index, anything).and_return(king_to_mate)
      allow(king_to_mate).to receive(:is_a?).with(King).and_return(true)
      allow(king_to_mate).to receive(:to_yaml).and_return('')
      allow(King).to receive(:new).with(mated_player_index ^ 1, anything).and_call_original
      allow(game).to receive(:puts)
      allow(game).to receive(:display_board)
      game.instance_variable_set(:@curr_player_index, mated_player_index)
      game.instance_variable_get(:@board).each do |piece|
        allow(piece).to receive(:legal_next_positions).and_return([])
      end
    end

    context 'when a player checkmates their opponent' do
      before do
        allow(king_to_mate).to receive(:checked?).and_return(true)
      end

      10.times do
        it 'outputs a checkmate and win game message' do
          checkmate_message_reg = Regexp.new("#{mating_player.color} gives checkmate to #{mated_player.color}. #{mating_player.name} has won the game!")
          expect(game).to receive(:puts).with(checkmate_message_reg)
          game.display_mate_state
        end

        it 'ends the game' do
          game.display_mate_state
          game_over = game.instance_variable_get(:@game_over)
          expect(game_over).to be true
        end
      end
    end

    context 'when the game is stalemated' do
      before do
        allow(king_to_mate).to receive(:checked?).and_return(false)
      end

      10.times do
        it 'outputs a stalemate and draw message' do
          stalemate_message_reg = Regexp.new("#{mated_player.color} gets a stalemate. The game is a draw.")
          expect(game).to receive(:puts).with(stalemate_message_reg)
          game.display_mate_state
        end

        it 'ends the game' do
          game.display_mate_state
          game_over = game.instance_variable_get(:@game_over)
          expect(game_over).to be true
        end
      end
    end

    context 'when the opponent still has legal moves' do
      before do
        allow(King).to receive(:new).with(mated_player_index, anything).and_return(king_to_mate)
        allow(king_to_mate).to receive(:is_a?).with(King).and_return(true)
        allow(king_to_mate).to receive(:checked?).and_return([true, false].sample)
        allow(King).to receive(:new).with(mated_player_index ^ 1, anything).and_call_original
        allow(game).to receive(:puts)
        allow(game).to receive(:display_board)
        game.instance_variable_set(:@curr_player_index, mated_player_index)
        game.instance_variable_get(:@board).each do |piece|
          allow(piece).to receive(:legal_next_positions).and_return([ Array.new(2) { rand(8) }])
        end
      end

      10.times do
        it 'does not output a checkmate or stalemate message' do
          expect(game).not_to receive(:puts)
          game.display_mate_state
        end

        it 'does not end the game' do
          game.display_mate_state
          game_over = game.instance_variable_get(:@game_over)
          expect(game_over).not_to be true
        end
      end
    end
  end

  describe '#player_action' do
    let(:curr_player_index) { rand(2) }
    let(:curr_player) { [white_player, black_player][curr_player_index] }
    let(:opponent_player) { [white_player, black_player][curr_player_index ^ 1] }

    before do
      game.instance_variable_set(:@curr_player_index, curr_player_index)
      allow(game).to receive(:puts)
    end

    context 'when the word "menu" is entered' do
      context 'when the word "back" or "7" is entered' do
        before do
          allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[back BACK 7].sample)
        end

        10.times do
          it 'prompts the player for an input to determine their next action' do
            prompt_reg = Regexp.new("#{curr_player.name}, please enter the square of the piece that you wish to move\..+\(Or enter the word MENU to view other game options\.\)")
            expect(game).to receive(:puts).with(prompt_reg)
            game.player_action
          end

          it 'outputs a list of game menu options' do
            expect(game).to receive(:puts).with(/Enter one of the following words to select the corresponding option:/)
            game.player_action
          end
        end
      end

      context 'while the word "help" or "1" is entered' do
        10.times do
          it 'outputs chess instructions the corresponding number of times' do
            help_count = rand(1..100)
            call_count = 0
            allow(game).to receive(:gets) do
              call_count += 1
              if call_count == 1
                %w[menu MENU].sample
              elsif call_count == (help_count * 2) + 2
                'back'
              elsif call_count.even?
                %w[help HELP 1].sample
              else ''
              end
            end

            expect(game).to receive(:puts).with(/Chess is a board game with two players/).exactly(help_count).times
            game.player_action
          end
        end
      end

      context 'when the word "resign" or "2" is entered' do
        context 'when the player confirms that they wish to resign' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[resign RESIGN 2].sample, %w[y Y yes YES].sample)
          end

          10.times do
            it 'outputs a warning to player' do
              expect(game).to receive(:puts).with("WARNING: This will end the game.\r\nAre you sure you wish to resign the game to your opponent? (Y/N)")
              game.player_action
            end

            it 'outputs an opponent win game message' do
              expect(game).to receive(:puts).with("#{opponent_player.name} has won the game!")
              game.player_action
            end

            it 'ends the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).to be true
            end
          end
        end

        context 'when the player does not confirm that they wish to resign' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[resign RESIGN 2].sample, ['n', 'N', 'no', 'NO', 'yesterday', ''].sample, 'back')
          end

          10.times do
            it 'outputs a warning to player' do
              expect(game).to receive(:puts).with("WARNING: This will end the game.\r\nAre you sure you wish to resign the game to your opponent? (Y/N)")
              game.player_action
            end

            it 'does not output an opponent win game message' do
              expect(game).not_to receive(:puts).with("#{opponent_player.name} has won the game!")
              game.player_action
            end

            it 'does not end the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).not_to be true
            end
          end
        end
      end

      context 'when the word "draw" or "3" is entered' do
        context 'when the opponent accepts the draw' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[draw DRAW 3].sample, %w[y Y yes YES].sample)
          end

          10.times do
            it 'prompts the opponent to accept or decline the draw' do
              expect(game).to receive(:puts).with("#{opponent_player.name}, do you accept the proposal of draw?")
              game.player_action
            end

            it 'outputs a draw message' do
              expect(game).to receive(:puts).with('The game ends in a draw.')
              game.player_action
            end

            it 'ends the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).to be true
            end
          end
        end

        context 'when the opponent does not accept the draw' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[draw DRAW 3].sample, ['n', 'N', 'no', 'NO', 'yesterday', ''].sample)
          end

          10.times do
            it 'prompts the opponent to accept or decline the draw' do
              expect(game).to receive(:puts).with("#{opponent_player.name}, do you accept the proposal of draw?")
              game.player_action
            end

            it 'does not output a draw message' do
              expect(game).not_to receive(:puts).with('The game ends in a draw.')
              game.player_action
            end

            it 'does not end the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).not_to be true
            end
          end
        end
      end

      context 'while an invalid input is entered' do
        10.times do
          it 'prompts the user to enter an input until a valid input is entered' do
            invalid_count = rand(100)
            call_count = 0
            invalid_inputs = ["I don't know", 'menu', '20', 'b', '[0, 1]', ':help', '(']
            allow(game).to receive(:gets) do
              call_count += 1
              if call_count == 1
                'menu'
              elsif call_count == invalid_count + 2
                'back'
              else invalid_inputs.sample
              end
            end
            expect(game).to receive(:puts).with('Invalid input!').exactly(invalid_count).times
            game.player_action
          end
        end
      end
    end

    context 'when a position on the board is entered' do
      let(:movable_piece_position) { Array.new(2) { rand(8) } }
      let(:movable_piece_position_input) do
        ('a'..'h').to_a[movable_piece_position.first] + (movable_piece_position.last + 1).to_s
      end
      let(:piece_next_position) do
        loop do
          pos = Array.new(2) { rand(8) }
          return pos unless pos == movable_piece_position
        end
      end
      let(:movable_piece) { instance_double(Piece, player_index: curr_player_index, position: movable_piece_position) }
      let(:capturable_piece) { instance_double(Piece, player_index: curr_player_index ^ 1, position: piece_next_position) }
      let(:test_board) { [movable_piece, capturable_piece] }
      let(:random_move_num) { rand(100) }
      let(:random_idle_moves) { rand(1..48) }

      before do
        game.instance_variable_set(:@board, test_board)
        game.instance_variable_set(:@move_num, random_move_num)
        game.instance_variable_set(:@idle_moves, random_idle_moves)
        allow(movable_piece).to receive(:to_yaml).and_return('')
        allow(movable_piece).to receive(:legal_next_positions).and_return([piece_next_position])
        allow(movable_piece).to receive(:move) do
          allow(movable_piece).to receive(:position).and_return(piece_next_position)
        end
      end

      context 'when the position of a player piece that can be moved is entered' do
        before do
          allow(game).to receive(:gets).and_return(movable_piece_position_input)
        end

        10.times do
          it 'increases the move number of the game' do
            expect { game.player_action }.to change { game.instance_variable_get(:@move_num) }.by(1)
          end

          it 'sends a move message to the player piece' do
            expect(movable_piece).to receive(:move).with(test_board, random_move_num + 1)
            game.player_action
          end

          it "removes any captured pieces on the player piece's new position" do
            game.player_action
            expect(board).not_to include(capturable_piece)
          end

          it 'updates the game history' do
            expect { game.player_action }.to change { game.instance_variable_get(:@history).size }.by(1)
          end
        end

        context "when an opponent piece is captured by the player's move" do
          10.times do
            it 'resets number of idle moves to zero' do
              game.player_action
              idle_moves = game.instance_variable_get(:@idle_moves)
              expect(idle_moves).to eql(0)
            end
          end
        end

        context 'when the player piece is a pawn' do
          let(:movable_piece) { instance_double(Pawn, player_index: curr_player_index, position: movable_piece_position) }
          before do
            allow(game).to receive(:display_board)
            allow(movable_piece).to receive(:is_a?).with(Pawn).and_return(true)
            allow(movable_piece).to receive(:en_passant).and_return(false)
          end

          context 'when the player piece is ready for promotion' do
            let(:class_input) do
              [[%w[knight KNIGHT].sample, Knight],
               [%w[rook ROOK].sample, Rook],
               [%w[bishop BISHOP].sample, Bishop],
               [%w[queen QUEEN].sample, Queen]].sample
            end

            before do
              allow(movable_piece).to receive(:promoting).and_return(true)
            end

            context 'when the player enters a valid class to promote the pawn' do
              before do
                allow(game).to receive(:gets).and_return(movable_piece_position_input, class_input.first)
              end

              10.times do
                it 'resets number of idle moves to zero' do
                  game.player_action
                  idle_moves = game.instance_variable_get(:@idle_moves)
                  expect(idle_moves).to eql(0)
                end

                it 'prompts the player to select a class to promote the pawn' do
                  expect(game).to receive(:puts).with(/Please enter the piece type to promote your pawn to:/)
                  game.player_action
                end

                it 'promotes the pawn to the selected class on the board' do
                  game.player_action
                  new_piece = board.find { |piece| piece.position == piece_next_position }
                  expect(new_piece).to be_a(class_input.last)
                end
              end
            end

            context 'while the player enters an invalid input to promote the pawn' do
              10.times do
                it 'prompts the player to enter a class to promote the pawn until a valid input is entered' do
                  invalid_count = rand(100)
                  call_count = 0
                  invalid_inputs = ['pawn', 'KING', "I don't know", 'menu', '20', 'b', '[0, 1]', ':help', '(']
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1
                      movable_piece_position_input
                    elsif call_count == invalid_count + 2
                      class_input.first
                    else invalid_inputs.sample
                    end
                  end
                  expect(game).to receive(:puts).with(/Invalid input! Please enter the piece type to promote your pawn to/).exactly(invalid_count).times
                  game.player_action
                end
              end
            end
          end

          context 'when the player piece is not ready for promotion' do
            before do
              allow(movable_piece).to receive(:promoting).and_return(false)
            end

            10.times do
              it 'resets number of idle moves to zero' do
                game.player_action
                idle_moves = game.instance_variable_get(:@idle_moves)
                expect(idle_moves).to eql(0)
              end

              it 'does not prompt the player to select a class to promote the pawn' do
                expect(game).not_to receive(:puts).with(/Please enter the piece type to promote your pawn to:/)
                game.player_action
              end
            end
          end
        end

        context 'when the move does not capture a piece and the player piece is not a pawn' do
          10.times do
            it 'adds 1 to the number of idle moves' do
              game.instance_variable_set(:@board, [movable_piece])
              game.player_action
              idle_moves = game.instance_variable_get(:@idle_moves)
              expect(idle_moves).to eql(random_idle_moves + 1)
            end
          end
        end
      end

      context 'while the position of a player piece that cannot be moved is entered' do
        let(:unmovable_piece_position) do
          loop do
            pos = Array.new(2) { rand(8) }
            unless [movable_piece_position, piece_next_position].include?(pos)
              return pos
            end
          end
        end
        let(:unmovable_piece_position_input) do
          ('a'..'h').to_a[unmovable_piece_position.first] + (unmovable_piece_position.last + 1).to_s
        end
        let(:unmovable_piece) { instance_double(Piece, player_index: curr_player_index, position: unmovable_piece_position) }
        let(:test_board) { [movable_piece, capturable_piece, unmovable_piece] }

        10.times do
          it 'prompts the user to enter a position until a valid position is entered' do
            allow(unmovable_piece).to receive(:to_yaml).and_return('')
            allow(unmovable_piece).to receive(:legal_next_positions).and_return([])
            invalid_count = rand(1..100)
            call_count = 0
            allow(game).to receive(:gets) do
              call_count += 1
              call_count == invalid_count + 1 ? movable_piece_position_input : unmovable_piece_position_input
            end
            error_reg = /There are no legal moves for this piece\. Please select a different piece to move\. Please enter the square of the piece that you wish to move/
            expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
            game.player_action
          end
        end
      end

      context 'while the position of a square without a player piece is entered' do
        let(:empty_position) do
          loop do
            pos = Array.new(2) { rand(8) }
            unless [movable_piece_position, piece_next_position].include?(pos)
              return pos
            end
          end
        end
        let(:empty_position_input) do
          ('a'..'h').to_a[empty_position.first] + (empty_position.last + 1).to_s
        end

        10.times do
          it 'prompts the user to enter a position until a valid position is entered' do
            invalid_count = rand(1..100)
            call_count = 0
            allow(game).to receive(:gets) do
              call_count += 1
              call_count == invalid_count + 1 ? movable_piece_position_input : empty_position_input
            end
            error_reg = /You don't have a piece on that square! Please enter the square of the piece that you wish to move/
            expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
            game.player_action
          end
        end
      end
    end

    context 'while an invalid input is entered' do
      10.times do
        it 'prompts the user to enter an input until a valid input is entered' do
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ["I don't know", 'Z1', 'A9', 'f23', 'b', '[0, 1]', '20', 'no', ':help', '(']
          allow(game).to receive(:gets) do
            call_count += 1
            if call_count == invalid_count + 1
              'menu'
            elsif call_count == invalid_count + 2
              'back'
            else invalid_inputs.sample
            end
          end
          error_reg = /Invalid input! Please enter the square of the piece that you wish to move.+\(Or enter the word MENU to view other game options\.\)/
          expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
          game.player_action
        end
      end
    end
  end
end
