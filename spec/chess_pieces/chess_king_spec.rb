require_relative '../../lib/chess_pieces/chess_king.rb'
require_relative '../../lib/chess_pieces/chess_rook.rb'
require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe King do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:king) { described_class.new(player_index, random_position) }
  let(:random_move_num) { rand(50) }
  let(:legal_position) do
    loop do
      position = [random_position.first + [1, 0, -1].sample,
                  random_position.last + [1, 0, -1].sample]
      if position != random_position && position.all? { |dir| dir.between?(0, 7) }
        return position
      end
    end
  end

  describe '#move' do
    it 'sets the moved variable to true' do
      king.move(legal_position)
      expect(king.moved).to be true
    end
  end

  describe '#legal_next_positions' do
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while (position.first - random_position.first).abs <= 1 &&
            (position.last - random_position.last).abs <= 1
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:legal_positions) { king.legal_next_positions([king], random_move_num) }

    before do
      allow(king).to receive(:checked?).and_return(false)
    end

    10.times do
      it 'includes legal positions' do
        expect(legal_positions).to include(legal_position)
      end

      it 'excludes illegal positions' do
        expect(legal_positions).not_to include(illegal_position)
      end
    end

    context 'when a position would place the king in check' do
      before do
        allow(king).to receive(:checked?).with(legal_position, any_args).and_return(true)
      end

      10.times do
        it 'excludes the position' do
          expect(legal_positions).not_to include(legal_position)
        end

        it 'includes the position in the illegal_check_next_positions variable' do
          legal_positions
          expect(king.illegal_check_next_positions).to include(legal_position)
        end
      end
    end

    context 'when there is a piece in the path of the king' do
      let(:blocking_position) do
        loop do
          position = [random_position.first + [1, 0, -1].sample,
                      random_position.last + [1, 0, -1].sample]
          if position != random_position &&
             position != legal_position &&
             position.all? { |dir| dir.between?(0, 7) }
            return position
          end
        end
      end
      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [king, blocking_piece] }
      let(:legal_positions) { king.legal_next_positions(board, random_move_num) }

      context "when the piece is the opponent's" do
        10.times do
          it 'includes the occupied position' do
            allow(blocking_piece).to receive(:player_index).and_return(player_index ^ 1)
            expect(legal_positions).to include(blocking_position)
          end
        end
      end

      context "when the piece is the player's own" do
        10.times do
          it 'excludes the occupied position' do
            allow(blocking_piece).to receive(:player_index).and_return(player_index)
            expect(legal_positions).not_to include(blocking_position)
          end
        end
      end
    end
  end

  describe '#checked?' do
    before do
      allow(king).to receive(:checked?).and_call_original
    end
    context "when an opponent's piece can check the player's king" do
      10.times do
        it 'returns true' do
          checking_piece = instance_double(Piece, player_index: player_index ^ 1, next_positions: [random_position])
          result = king.checked?(random_position, [checking_piece, king], random_move_num)
          expect(result).to be true
        end
      end
    end

    context "when no piece can check the player's king" do
      10.times do
        it 'returns false' do
          board = [instance_double(Piece, player_index: player_index, next_positions: [random_position]),
                   instance_double(Piece, player_index: player_index ^ 1, next_positions: []),
                   king]
          result = king.checked?(random_position, board, random_move_num)
          expect(result).to be false
        end
      end
    end
  end
end
