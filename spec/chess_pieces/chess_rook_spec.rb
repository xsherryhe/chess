require_relative '../../lib/chess_pieces/chess_rook.rb'
require_relative '../../lib/chess_pieces/chess_king.rb'
require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe Rook do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:rook) { described_class.new(player_index, random_position) }
  let(:legal_position) do
    loop do
      change = rand(1..7) * [1, -1].sample
      position = [[random_position.first + change, random_position.last],
                  [random_position.first, random_position.last + change]]
                 .sample
      return position if position.all? { |dir| dir.between?(0, 7) }
    end
  end

  describe '#move' do
    it 'sets the moved variable to true' do
      rook.move(legal_position)
      expect(rook.moved).to be true
    end
  end

  describe '#legal_next_positions' do
    let(:random_move_num) { rand(50) }
    let(:player_king) { instance_double(King, player_index: player_index, position: [-1, -1]) }
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while position.first == random_position.first ||
            position.last == random_position.last
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:legal_positions) { rook.legal_next_positions([player_king, rook], random_move_num) }

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
          expect(rook.illegal_check_next_positions).to include(legal_position)
        end
      end
    end

    context 'when there is a piece in the path of the rook' do
      let(:blocking_position) do
        loop do
          change = rand(2..5) * [1, -1].sample
          position = [[random_position.first + change, random_position.last],
                      [random_position.first, random_position.last + change]]
                     .sample
          valid = position.first == random_position.first && position.last.between?(2, 5) ||
                  position.first.between?(2, 5) && position.last == random_position.last
          return position if valid
        end
      end
      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [blocking_piece, player_king, rook] }
      let(:legal_positions) { rook.legal_next_positions(board, random_move_num) }
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
