require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(HumanPlayer, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(HumanPlayer, name: 'Bar', player_index: 1, color: 'Black') }
  let(:players) { game.instance_variable_get(:@players) }
  let(:board) { game.board }

  before do
    allow(HumanPlayer).to receive(:new).and_return(white_player, black_player)
    allow(game).to receive(:display_board)
    allow(game).to receive(:puts)
  end

  describe '#initialize' do
    context 'when the game has no custom setup' do
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

      context 'when the game is between two human players' do
        it 'creates two new human players with player indices 0 and 1' do
          expect(HumanPlayer).to receive(:new).with(0).once
          expect(HumanPlayer).to receive(:new).with(1).once
          Game.new
        end
      end

      context 'when the game has a computer player' do
        subject(:computer_player_game) { Game.new(false, true) }
        let(:computer_player_ind) { [0, 1].sample }

        before do
          allow_any_instance_of(Object).to receive(:rand).with(2).and_return(computer_player_ind)
          allow(ComputerPlayer).to receive(:new) do |player_index|
            instance_double(ComputerPlayer, name: 'Computer', player_index: player_index)
          end
          allow(HumanPlayer).to receive(:new) do |player_index|
            instance_double(HumanPlayer, name: 'Foo', player_index: player_index)
          end
        end

        10.times do
          it 'creates a computer player with a player index of 0 or 1' do
            expect(ComputerPlayer).to receive(:new).with(computer_player_ind)
            computer_player_game
          end

          it 'creates a human player with the other player index' do
            expect(HumanPlayer).to receive(:new).with(computer_player_ind ^ 1)
            computer_player_game
          end
        end
      end
    end

    context 'when the game has a custom setup' do
      subject(:game) { Game.new(true) }

      it 'does not create a starting board' do
        expect(board).to be nil
      end

      it 'does not create new players' do
        expect(players).to be nil
      end
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
    let(:target_piece_position) { Array.new(2) { rand(8) } }
    let(:piece_next_position) do
      loop do
        pos = Array.new(2) { rand(8) }
        return pos unless pos == target_piece_position
      end
    end
    let(:target_piece) { instance_double(Piece, player_index: curr_player_index, position: target_piece_position) }
    let(:capturable_piece) { instance_double(Piece, player_index: curr_player_index ^ 1, position: piece_next_position) }
    let(:test_board) { [target_piece, capturable_piece] }
    let(:random_move_num) { rand(100) }
    let(:random_idle_moves) { rand(1..48) }

    before do
      game.instance_variable_set(:@curr_player_index, curr_player_index)
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

    context 'when the action is a player piece and a legal next position of the player piece' do
      before do
        allow(curr_player).to receive(:select_action).with(game).and_return([target_piece, piece_next_position])
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
          let(:promote_class) do
            [Knight, Queen, Bishop, Rook].sample
          end

          before do
            allow(target_piece).to receive(:promoting).and_return(true)
            allow(curr_player).to receive(:select_promote_class).and_return(promote_class)
          end

          10.times do
            it 'resets number of idle moves to zero' do
              game.player_action
              idle_moves = game.instance_variable_get(:@idle_moves)
              expect(idle_moves).to eql(0)
            end

            it 'outputs a message that the pawn must promote' do
              expect(game).to receive(:puts).with(/your pawn must promote/)
              game.player_action
            end

            it 'promotes the pawn to the selected class on the board' do
              game.player_action
              new_piece = board.find { |piece| piece.position == piece_next_position }
              expect(new_piece).to be_a(promote_class)
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

            it 'does not output a message that the pawn must promote' do
              expect(game).not_to receive(:puts).with(/your pawn must promote/)
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

    context "when the action is the string 'castle'" do
      let(:player_rook) { instance_double(Rook, player_index: curr_player_index, position: [[0, 7].sample, 7 * curr_player_index], moved: false) }
      let(:player_king) { instance_double(King, player_index: curr_player_index, position: [4, 7 * curr_player_index], moved: false) }
      let(:target_piece_position) { [rand(8), rand(1..6)] }
      let(:test_board) { [player_rook, player_king, target_piece] }

      before do
        [player_rook, player_king].each do |piece|
          allow(piece).to receive(:is_a?).and_return(false)
          allow(piece).to receive(:move) do |new_pos, _move_num|
            allow(piece).to receive(:position).and_return(new_pos)
          end
        end

        allow(player_king).to receive(:is_a?).with(King).and_return(true)
        allow(player_king).to receive(:checked?).and_return(false)
        allow(player_rook).to receive(:is_a?).with(Rook).and_return(true)
        allow(curr_player).to receive(:select_action).and_return(%w[castle CASTLE].sample)
        allow(curr_player).to receive(:select_rook).with([player_rook], game).and_return(player_rook)
      end

      10.times do
        it 'increases the move number of the game' do
          expect { game.player_action }.to change { game.instance_variable_get(:@move_num) }.by(1)
        end

        it "sends a move message to the player rook with the rook's castling position and the updated move number" do
          new_rook_position = [player_rook.position.first.zero? ? 3 : 5, curr_player_index * 7]
          expect(player_rook).to receive(:move).with(new_rook_position, random_move_num + 1)
          game.player_action
        end

        it "sends a move message to the player king with the king's castling position and the updated move number" do
          new_king_position = [player_rook.position.first.zero? ? 2 : 6, curr_player_index * 7]
          expect(player_king).to receive(:move).with(new_king_position, random_move_num + 1)
          game.player_action
        end

        it 'updates the game history' do
          expect { game.player_action }.to change { game.instance_variable_get(:@history).size }.by(1)
        end

        it 'adds 1 to the number of idle moves' do
          game.player_action
          idle_moves = game.instance_variable_get(:@idle_moves)
          expect(idle_moves).to eql(random_idle_moves + 1)
        end
      end
    end
  end
end
