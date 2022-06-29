require_relative '../../lib/chess_pieces/chess_knight.rb'
require_relative '../../lib/chess_pieces/chess_king.rb'
require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe Knight do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:knight) { described_class.new(player_index, random_position) }

  describe '#legal_next_positions' do
    let(:random_move_num) { rand(50) }
    let(:player_king) { instance_double(King, player_index: player_index, position: [-1, -1]) }
    let(:legal_position) do
      moves = [[-1, -2], [-1, 2], [1, -2], [1, 2], [-2, -1], [-2, 1], [2, -1], [2, 1]]
      loop do
        position = moves.sample.map.with_index { |change, i| random_position[i] + change }
        return position if position.all? { |dir| dir.between?(0, 7) }
      end
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      position = Array.new(2) { rand(8) } until [(position.first - random_position.first).abs,
                                                 (position.last - random_position.last).abs]
                                                .all? { |diff| diff > 2 }
      position
    end
    let(:legal_positions) { knight.legal_next_positions([player_king], random_move_num) }

    before do
      allow(player_king).to receive(:is_a?).with(King).and_return(true)
      allow(player_king).to receive(:checked?).and_return(false)
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
        allow(player_king).to receive(:checked?).with(anything, array_including(having_attributes(position: legal_position)), anything).and_return(true)
      end

      10.times do
        it 'excludes the position' do
          expect(legal_positions).not_to include(legal_position)
        end

        it 'includes the position in the illegal_check_next_positions variable' do
          legal_positions
          expect(knight.illegal_check_next_positions).to include(legal_position)
        end
      end
    end

    context 'when there is a piece in the path of the knight' do
      let(:blocking_position) do
        moves = [[-1, -2], [-1, 2], [1, -2], [1, 2], [-2, -1], [-2, 1], [2, -1], [2, 1]]
        loop do
          position = moves.sample.map.with_index { |change, i| random_position[i] + change }
          if position.all? { |dir| dir.between?(0, 7) } && position != legal_position
            return position
          end
        end
      end
      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [player_king, blocking_piece] }
      let(:legal_positions) { knight.legal_next_positions(board, random_move_num) }

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
end
