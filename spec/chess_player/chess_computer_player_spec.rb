require_relative '../../lib/chess_player.rb'
require_relative '../../lib/chess_game.rb'

describe ComputerPlayer do
  let(:player_index) { rand(2) }
  subject(:player) { described_class.new(player_index, 'Computer') }

  before do
    allow(player).to receive(:puts)
    allow(player).to receive(:sleep)
    allow(player).to receive(:gets).and_return('')
  end

  describe '#initialize' do
    context 'when the name argument is not provided' do
      subject(:no_name_player) { described_class.new(player_index) }

      before do
        allow_any_instance_of(Object).to receive(:puts)
      end

      10.times do
        it 'outputs a message with the color of the computer player' do
          color = %w[White Black][player_index]
          expect_any_instance_of(Object).to receive(:puts).with("Computer is the #{color} player.")
          no_name_player
        end

        it 'sets the name variable to the string "Computer"' do
          player_name = no_name_player.name
          expect(player_name).to eq('Computer')
        end
      end
    end
  end

  describe '#select_action' do
    let(:target_piece_positions) do
      positions = []
      10.times do
        pos = Array.new(2) { rand(8) }
        positions << pos unless positions.include?(pos)
      end
      positions
    end
    let(:piece_next_positions) do
      positions = []
      10.times do
        pos = Array.new(2) { rand(8) }
        positions << pos unless positions.include?(pos)
      end
      positions
    end
    let(:board) do
      target_piece_positions.map do |pos|
        target_piece = instance_double(Piece, player_index: player_index, position: pos)
        next_positions = piece_next_positions.sample(3).reject { |next_pos| next_pos == pos }
        allow(target_piece).to receive(:legal_next_positions).and_return(next_positions)
        allow(target_piece).to receive(:illegal_check_next_positions).and_return([])
        target_piece
      end
    end
    let(:random_move_num) { rand(100) }
    let(:game) { instance_double(Game, board: board, move_num: random_move_num) }

    before do
      allow(game).to receive(:can_castle?).and_return(false)
    end

    it 'outputs a message indicating a computer move' do
      expect(player).to receive(:puts).with('Computer move:')
      player.select_action(game)
    end

    10.times do
      it 'returns a target piece and a legal next position for the target piece' do
        target_piece, piece_next_position = player.select_action(game)
        expect(board).to include(target_piece)
        expect(target_piece.legal_next_positions(board, random_move_num)).to include(piece_next_position)
      end

      it "outputs a message describing the computer's move" do
        action = player.select_action(game)
        target_piece_position = action.first.position
        piece_next_position = action.last
        target_piece_position_output = ('A'..'H').to_a[target_piece_position.first] + (target_piece_position.last + 1).to_s
        piece_next_position_output = ('A'..'H').to_a[piece_next_position.first] + (piece_next_position.last + 1).to_s
        output = "#{target_piece_position_output} to #{piece_next_position_output}"
        expect(player).to have_received(:puts).with(output)
      end
    end

    context 'when a castling move is possible' do
      before do
        allow(game).to receive(:can_castle?).and_return(true)
      end

      it 'can return the string "castle"' do
        allow(game).to receive(:board).and_return([])
        action = player.select_action(game)
        expect(action).to eq('castle')
      end

      10.times do
        it 'can still return a target piece and a legal next position for the target piece, or can return the string "castle"' do
          action = player.select_action(game)
          if action.is_a?(Array)
            target_piece, piece_next_position = action
            expect(board).to include(target_piece)
            expect(target_piece.legal_next_positions(board, random_move_num)).to include(piece_next_position)
          else
            expect(action).to eq('castle')
          end
        end
      end
    end
  end

  describe '#select_rook' do
    let(:player_rook1) { instance_double(Rook, position: [0, 7 * player_index]) }
    let(:player_rook2) { instance_double(Rook, position: [7, 7 * player_index]) }
    let(:random_move_num) { rand(100) }
    let(:game) { instance_double(Game, move_num: random_move_num) }

    context 'when a castling move is possible with one rook' do
      let(:rooks) { [[player_rook1, player_rook2].sample] }

      10.times do
        it 'returns the rook that can be castled with' do
          rook = player.select_rook(rooks, game)
          expect(rooks).to include(rook)
        end

        it "outputs a message describing the computer's castle move" do
          rook_position = rooks.first.position
          rook_position_output = ('A'..'H').to_a[rook_position.first] + (rook_position.last + 1).to_s
          expect(player).to receive(:puts).with("Castle king with rook at #{rook_position_output}")
          player.select_rook(rooks, game)
        end
      end
    end

    context 'when a castling move is possible with both rooks' do
      let(:rooks) { [player_rook1, player_rook2] }

      10.times do
        it 'returns a rook that can be castled with' do
          rook = player.select_rook(rooks, game)
          expect(rooks).to include(rook)
        end

        it "outputs a message describing the computer's castle move" do
          rook = player.select_rook(rooks, game)
          rook_position = rook.position
          rook_position_output = ('A'..'H').to_a[rook_position.first] + (rook_position.last + 1).to_s
          expect(player).to have_received(:puts).with("Castle king with rook at #{rook_position_output}")
        end
      end
    end
  end

  describe '#select_promote_class' do
    let(:promote_classes) { [Queen, Bishop, Knight, Rook] }

    10.times do
      it 'returns a valid promote class' do
        promote_class = player.select_promote_class
        expect(promote_classes).to include(promote_class)
      end

      it 'outputs a message indicating the selected promote class' do
        promote_class = player.select_promote_class
        expect(player).to have_received(:puts).with("Computer promotes pawn to #{promote_class.name}.")
      end
    end
  end

  describe '#claim_draw?' do
    it 'returns the string "no"' do
      claim_draw = player.claim_draw?
      expect(claim_draw).to eq('no')
    end
  end

  describe '#accept_draw?' do
    it 'returns the string "yes"' do
      accept_draw = player.accept_draw?
      expect(accept_draw).to eq('yes')
    end

    it "outputs a message indicating the computer's acceptance of draw" do
      expect(player).to receive(:puts).with('Computer accepts the draw.')
      player.accept_draw?
    end
  end
end
