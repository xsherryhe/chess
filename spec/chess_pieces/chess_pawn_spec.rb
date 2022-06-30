require_relative '../../lib/chess_pieces/chess_pawn.rb'
require_relative '../../lib/chess_pieces/chess_king.rb'

describe Pawn do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(1..6) }
  end
  subject(:pawn) { described_class.new(player_index, random_position) }
  let(:random_move_num) { rand(50) }
  let(:double_step_position) { [pawn.position.first, pawn.position.last + [2, -2][player_index]] }

  describe '#move' do
    context 'when the pawn is moving to the final row' do
      let(:final_row_position) { [random_position.first, 7 * (player_index ^ 1)] }

      10.times do
        it "changes the pawn's promoting variable to true" do
          pawn.position = [random_position.first, [6, 1][player_index]]
          pawn.move(final_row_position, random_move_num)
          expect(pawn.promoting).to be true
        end
      end
    end

    context 'when the pawn is moving to a double-step position' do
      10.times do
        it 'changes the double-step variable to be the move number' do
          pawn.position = [random_position.first, [1, 6][player_index]]
          pawn.move(double_step_position, random_move_num)
          expect(pawn.double_step).to eq(random_move_num)
        end
      end
    end

    context 'when the pawn moves after a double-step' do
      let(:double_step_move_num) do
        move_num = rand(50) while move_num == random_move_num
        move_num
      end

      10.times do
        it 'does not change the double-step variable' do
          pawn.instance_variable_set(:@double_step, double_step_move_num)
          pawn.position = [random_position.first, [3, 4][player_index]]
          next_position = [random_position.first, pawn.position.last + (player_index.zero? ? 1 : -1)]
          pawn.move(next_position, random_move_num)
          expect(pawn.double_step).to eq(double_step_move_num)
        end
      end
    end
  end

  describe '#legal_next_positions' do
    let(:opponent_index) { player_index ^ 1 }
    let(:player_king) { instance_double(King, player_index: player_index, position: [-1, -1]) }
    let(:legal_position) do
      [random_position.first, random_position.last + (player_index.zero? ? 1 : -1)]
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      position = Array.new(2) { rand(8) } until [(position.first - random_position.first).abs,
                                                 (position.last - random_position.last).abs]
                                                .all? { |diff| diff > 2 }
      position
    end
    let(:diagonal_position) do
      [random_position.first + [1, -1].sample, random_position.last + (player_index.zero? ? 1 : -1)]
    end
    let(:adjacent_position) { [diagonal_position.first, random_position.last] }
    let(:legal_positions) { pawn.legal_next_positions([player_king, pawn], random_move_num) }

    before do
      allow(player_king).to receive(:is_a?).with(King).and_return(true)
      allow(player_king).to receive(:is_a?).with(Pawn).and_return(false)
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

    context 'when an opponent piece can be captured (is diagonal from the pawn)' do
      10.times do
        it 'includes diagonal positions' do
          opponent_piece = instance_double(Piece, player_index: opponent_index, position: diagonal_position)
          legal_positions = pawn.legal_next_positions([player_king, opponent_piece, pawn], random_move_num)
          expect(legal_positions).to include(diagonal_position)
        end
      end
    end

    context 'when an opponent pawn can be captured en passant' do
      10.times do
        it 'includes the diagonal position for en passant capture' do
          opponent_pawn = instance_double(Pawn, player_index: opponent_index, position: adjacent_position, double_step: random_move_num - 1)
          allow(opponent_pawn).to receive(:is_a?).with(Pawn).and_return(true)
          legal_positions = pawn.legal_next_positions([player_king, opponent_pawn, pawn], random_move_num)
          expect(legal_positions).to include(diagonal_position)
        end
      end
    end

    context 'when an opposing piece cannot be captured' do
      let(:uncapturable_piece) do
        [instance_double(Pawn, player_index: opponent_index, position: illegal_position, double_step: random_move_num - 1),
         instance_double(Piece, player_index: player_index, position: diagonal_position),
         instance_double(Pawn, player_index: opponent_index, position: adjacent_position, double_step: random_move_num + rand(10)),
         instance_double(Piece, player_index: opponent_index, position: [diagonal_position.first - 2, diagonal_position.last])]
          .sample
      end

      10.times do
        it 'does not include diagonal positions' do
          legal_positions = pawn.legal_next_positions([player_king, uncapturable_piece, pawn], random_move_num)
          expect(legal_positions).not_to include(diagonal_position)
        end
      end
    end

    context 'when the pawn is in starting position' do
      10.times do
        it 'includes the double-step position' do
          pawn.position = [random_position.first, [1, 6][player_index]]
          expect(legal_positions).to include(double_step_position)
        end
      end
    end

    context 'when the pawn is not in starting position' do
      10.times do
        it 'does not include the double-step position' do
          pawn.position = [random_position.first, (2..5).to_a.sample]
          expect(legal_positions).not_to include(double_step_position)
        end
      end
    end
  end
end
