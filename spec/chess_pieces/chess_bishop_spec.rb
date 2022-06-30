require_relative '../../lib/chess_pieces/chess_bishop.rb'
require_relative '../../lib/chess_pieces/chess_king.rb'
require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe Bishop do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:bishop) { described_class.new(player_index, random_position) }

  describe '#legal_next_positions' do
    let(:random_move_num) { rand(50) }
    let(:player_king) { instance_double(King, player_index: player_index, position: [-1, -1]) }
    let(:legal_position) do
      loop do
        distance = rand(1..7)
        position = [random_position.first + distance * [1, -1].sample,
                    random_position.last + distance * [1, -1].sample]
        return position if position.all? { |dir| dir.between?(0, 7) }
      end
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while (position.first - random_position.first).abs ==
            (position.last - random_position.last).abs
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:legal_positions) { bishop.legal_next_positions([player_king, bishop], random_move_num) }

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

    context "when a position would place the player's king in check" do
      before do
        allow(player_king).to receive(:checked?).with(anything, array_including(having_attributes(position: legal_position)), anything).and_return(true)
      end

      10.times do
        it 'excludes the position' do
          expect(legal_positions).not_to include(legal_position)
        end

        it 'includes the position in the illegal_check_next_positions variable' do
          legal_positions
          expect(bishop.illegal_check_next_positions).to include(legal_position)
        end
      end
    end

    context 'when there is a piece in the path of the bishop' do
      let(:blocking_position) do
        loop do
          distance = rand(2..5)
          position = [random_position.first + distance * [1, -1].sample,
                      random_position.last + distance * [1, -1].sample]
          return position if position.all? { |dir| dir.between?(2, 5) }
        end
      end
      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [player_king, blocking_piece, bishop] }
      let(:legal_positions) { bishop.legal_next_positions(board, random_move_num) }
      let(:before_position) do
        [random_position.first + (blocking_position.first <=> random_position.first),
         random_position.last + (blocking_position.last <=> random_position.last)]
      end
      let(:after_position) do
        [blocking_position.first + (blocking_position.first <=> random_position.first),
         blocking_position.last + (blocking_position.last <=> random_position.last)]
      end

      before do
        allow(blocking_piece).to receive(:player_index).and_return(rand(2))
      end

      10.times do
        it 'includes positions before the occupied position' do
          expect(legal_positions).to include(before_position)
        end

        it 'excludes positions after the occupied position' do
          expect(legal_positions).not_to include(after_position)
        end
      end

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
