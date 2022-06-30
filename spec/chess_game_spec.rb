require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }
  let(:players) { game.instance_variable_get(:@players) }
  let(:board) { game.instance_variable_get(:@board) }

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
    allow(game).to receive(:display_board)
    allow(game).to receive(:puts)
  end

  describe '#initialize' do
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

  describe '#player_action' do
    let(:curr_player_index) { rand(2) }
    let(:curr_player) { [white_player, black_player][curr_player_index] }
    let(:opponent_player) { [white_player, black_player][curr_player_index ^ 1] }

    before do
      game.instance_variable_set(:@curr_player_index, curr_player_index)
      allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[back BACK 8].sample)
    end

    10.times do
      it 'prompts the player for an input to determine their next action' do
        prompt_reg = Regexp.new("#{curr_player.name}: Please enter the move you wish to make.+\\r\\n\\(Or enter the word MENU to view other game options\\.\\)")
        expect(game).to receive(:puts).with(prompt_reg)
        game.player_action
      end
    end

    context 'when a move input is entered' do
      let(:target_piece_position) { Array.new(2) { rand(8) } }
      let(:piece_next_position) do
        loop do
          pos = Array.new(2) { rand(8) }
          return pos unless pos == target_piece_position
        end
      end
      let(:move_input) do
        [('a'..'h').to_a[target_piece_position.first] + (target_piece_position.last + 1).to_s,
         ('a'..'h').to_a[piece_next_position.first] + (piece_next_position.last + 1).to_s]
          .join(['to', 'TO', ' to ', ' TO '].sample)
      end
      let(:target_piece) { instance_double(Piece, player_index: curr_player_index, position: target_piece_position) }
      let(:capturable_piece) { instance_double(Piece, player_index: curr_player_index ^ 1, position: piece_next_position) }
      let(:test_board) { [target_piece, capturable_piece] }
      let(:random_move_num) { rand(100) }
      let(:random_idle_moves) { rand(1..48) }

      before do
        game.instance_variable_set(:@board, test_board)
        game.instance_variable_set(:@move_num, random_move_num)
        game.instance_variable_set(:@idle_moves, random_idle_moves)
        allow(target_piece).to receive(:to_yaml).and_return('')
        allow(target_piece).to receive(:legal_next_positions).and_return([piece_next_position])
        allow(target_piece).to receive(:illegal_check_next_positions).and_return([])
        allow(target_piece).to receive(:move).with(piece_next_position, anything) do
          allow(target_piece).to receive(:position).and_return(piece_next_position)
        end
      end

      context 'when the position of a player piece and a legal next position for the piece are entered' do
        before do
          allow(game).to receive(:gets).and_return(move_input)
        end

        10.times do
          it 'increases the move number of the game' do
            expect { game.player_action }.to change { game.instance_variable_get(:@move_num) }.by(1)
          end

          it 'sends a move message to the player piece with the target next position for the piece and the updated move number' do
            expect(target_piece).to receive(:move).with(piece_next_position, random_move_num + 1)
            game.player_action
          end

          it 'updates the game history' do
            expect { game.player_action }.to change { game.instance_variable_get(:@history).size }.by(1)
          end
        end

        context "when an opponent piece is captured by the player's move" do
          10.times do
            it 'removes the captured piece' do
              game.player_action
              expect(board).not_to include(capturable_piece)
            end

            it 'resets number of idle moves to zero' do
              game.player_action
              idle_moves = game.instance_variable_get(:@idle_moves)
              expect(idle_moves).to eql(0)
            end
          end
        end

        context 'when the player piece is a pawn' do
          let(:target_piece) { instance_double(Pawn, player_index: curr_player_index, position: target_piece_position) }
          before do
            allow(target_piece).to receive(:is_a?).and_return(false)
            allow(target_piece).to receive(:is_a?).with(Pawn).and_return(true)
            allow(target_piece).to receive(:en_passant).and_return(false)
          end

          context 'when the player piece is ready for promotion' do
            let(:class_input) do
              [[%w[knight KNIGHT].sample, Knight],
               [%w[rook ROOK].sample, Rook],
               [%w[bishop BISHOP].sample, Bishop],
               [%w[queen QUEEN].sample, Queen]].sample
            end

            before do
              allow(target_piece).to receive(:promoting).and_return(true)
              allow(game).to receive(:gets).and_return(move_input, class_input.first)
            end

            context 'when the player enters a valid class to promote the pawn' do
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
                      move_input
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
              allow(target_piece).to receive(:promoting).and_return(false)
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
              game.instance_variable_set(:@board, [target_piece])
              game.player_action
              idle_moves = game.instance_variable_get(:@idle_moves)
              expect(idle_moves).to eql(random_idle_moves + 1)
            end
          end
        end
      end

      context 'while an input with the position of a square without a player piece is entered' do
        let(:empty_position) do
          loop do
            pos = Array.new(2) { rand(8) }
            unless [target_piece_position, piece_next_position].include?(pos)
              return pos
            end
          end
        end
        let(:empty_piece_position_input) do
          [('a'..'h').to_a[empty_position.first] + (empty_position.last + 1).to_s,
           ('a'..'h').to_a[piece_next_position.first] + (piece_next_position.last + 1).to_s]
            .join(['to', 'TO', ' to ', ' TO '].sample)
        end

        10.times do
          it 'prompts the user to enter a position until a valid position is entered' do
            invalid_count = rand(1..100)
            call_count = 0
            allow(game).to receive(:gets) do
              call_count += 1
              call_count == invalid_count + 1 ? move_input : empty_piece_position_input
            end
            error_reg = /You don't have a piece on that square!\r\nPlease enter the move you wish to make/
            expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
            game.player_action
          end
        end
      end

      context 'while an input with the position of a player piece and an illegal next position for the piece are entered' do
        let(:illegal_next_position) do
          loop do
            pos = Array.new(2) { rand(8) }
            unless [target_piece_position, piece_next_position].include?(pos)
              return pos
            end
          end
        end
        let(:illegal_move_input) do
          [('a'..'h').to_a[target_piece_position.first] + (target_piece_position.last + 1).to_s,
           ('a'..'h').to_a[illegal_next_position.first] + (illegal_next_position.last + 1).to_s]
            .join(['to', 'TO', ' to ', ' TO '].sample)
        end

        10.times do
          it 'prompts the user to enter a position until a valid position is entered' do
            invalid_count = rand(1..100)
            call_count = 0
            allow(game).to receive(:gets) do
              call_count += 1
              call_count == invalid_count + 1 ? move_input : illegal_move_input
            end
            error_reg = /Illegal move!\r\nPlease enter the move you wish to make/
            expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
            game.player_action
          end
        end

        context 'when the illegal next position would leave the king in check' do
          before do
            allow(target_piece).to receive(:illegal_check_next_positions).and_return([illegal_next_position])
          end

          10.times do
            it 'prompts the user with a message about leaving the king in check until a valid position is entered' do
              invalid_count = rand(1..100)
              call_count = 0
              allow(game).to receive(:gets) do
                call_count += 1
                call_count == invalid_count + 1 ? move_input : illegal_move_input
              end
              error_reg = /Illegal move! This move would leave your king in check\.\r\nPlease enter the move you wish to make/
              expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
              game.player_action
            end
          end
        end
      end
    end

    context 'while an invalid input is entered' do
      10.times do
        it 'prompts the user to enter an input until a valid input is entered' do
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ["I don't know", 'Z1', 'A9', 'Y1 to A8', 'B1 to A9', 'f23', 'b', '[0, 1]', '[1, 1] to [0, 1]', '20', 'no', ':help', '(']
          allow(game).to receive(:gets) do
            call_count += 1
            if call_count == invalid_count + 1
              'menu'
            elsif call_count == invalid_count + 2
              'back'
            else invalid_inputs.sample
            end
          end
          error_reg = /Invalid input!\r\nPlease enter the move you wish to make.+\(Or enter the word MENU to view other game options\.\)/
          expect(game).to receive(:puts).with(error_reg).exactly(invalid_count).times
          game.player_action
        end
      end
    end
  end
end
