require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe Pawn do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(1..6) }
  end
  subject(:pawn) { described_class.new(player_index, random_position) }

  describe '#move' do
    let(:legal_position) do
      [random_position.first, random_position.last + (player_index.zero? ? 1 : -1)]
    end
    let(:legal_position_input) do
      ('a'..'h').to_a[legal_position.first] + (legal_position.last + 1).to_s
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      position = Array.new(2) { rand(8) } until [(position.first - random_position.first).abs,
                                                 (position.last - random_position.last).abs]
                                                .all? { |diff| diff > 2 }
      position
    end
    let(:illegal_position_input) do
      ('a'..'h').to_a[illegal_position.first] + (illegal_position.last + 1).to_s
    end

    before do
      allow(pawn).to receive(:puts)
    end

    context 'when a legal position is entered' do
      before do
        allow(pawn).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(pawn).to receive(:puts).with('Please enter the square to move the pawn, using the format LETTER + NUMBER (e.g., "A1").')
          pawn.move([])
        end

        it "changes the pawn's position to the new position" do
          pawn.move([])
          expect(pawn.position).to eq(legal_position)
        end
      end
    end

    context 'while an illegal position is entered' do
      10.times do
        it 'prompts the user to enter a position until a legal position is entered' do
          illegal_inputs = rand(100)
          call_count = 0
          allow(pawn).to receive(:gets) do
            call_count += 1
            call_count == illegal_inputs + 1 ? legal_position_input : illegal_position_input
          end
          expect(pawn)
            .to receive(:puts)
            .with('Please enter a square for the pawn that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            .exactly(illegal_inputs).times
          pawn.move([])
        end
      end
    end

    context 'when a diagonal position is entered' do
      let(:diagonal_position) do
        [random_position.first + [1, -1].sample, random_position.last + (player_index.zero? ? 1 : -1)]
      end
      let(:diagonal_position_input) do
        ('a'..'h').to_a[diagonal_position.first] + (diagonal_position.last + 1).to_s
      end
      let(:adjacent_position) { [diagonal_position.first, random_position.last] }
      let(:adjacent_position_input) do
        ('a'..'h').to_a[adjacent_position.first] + (adjacent_position.last + 1).to_s
      end
      let(:opponent_index) { player_index ^ 1 }

      before do
        allow(pawn).to receive(:gets).and_return(diagonal_position_input)
      end

      context 'when an opposing piece can be captured (is diagonal from the pawn)' do
        10.times do
          it "allows the pawn's position to be changed" do
            pawn.move([instance_double(Piece, player_index: opponent_index, position: diagonal_position)])
            expect(pawn.position).to eq(diagonal_position)
          end
        end
      end

      context 'when an opposing pawn can be captured en passant' do
        10.times do
          it "allows the pawn's position to be changed" do
            opponent_pawn = instance_double(Pawn, player_index: opponent_index, position: adjacent_position, double_step: true)
            allow(opponent_pawn).to receive(:is_a?).with(Pawn).and_return(true)
            pawn.move([opponent_pawn])
            expect(pawn.position).to eq(diagonal_position)
          end
        end
      end

      context 'when an opposing piece cannot be captured' do
        let(:uncapturable_piece) do
          [instance_double(Pawn, player_index: opponent_index, position: illegal_position, double_step: true),
           instance_double(Piece, player_index: player_index, position: diagonal_position),
           instance_double(Pawn, player_index: opponent_index, position: adjacent_position, double_step: false),
           instance_double(Piece, player_index: opponent_index, position: [diagonal_position.first - 2, diagonal_position.last])]
            .sample
        end

        10.times do
          it 'prompts the user to enter a different position' do
            allow(pawn).to receive(:gets).and_return(diagonal_position_input, legal_position_input)
            expect(pawn).to receive(:puts).with('Please enter a square for the pawn that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            pawn.move([uncapturable_piece])
          end
        end
      end
    end

    context 'when a double-step position is entered' do
      let(:double_step_position) { [pawn.position.first, pawn.position.last + [2, -2][player_index]] }
      let(:double_step_position_input) do
        ('a'..'h').to_a[double_step_position.first] + (double_step_position.last + 1).to_s
      end

      context 'when the pawn is in starting position' do
        before do
          pawn.instance_variable_set(:@position, [random_position.first, [1, 6][player_index]])
          allow(pawn).to receive(:gets).and_return(double_step_position_input)
          pawn.move([])
        end

        10.times do
          it "allows the pawn's position to be changed" do
            expect(pawn.position).to eq(double_step_position)
          end

          it 'changes the double-step instance variable to be true' do
            expect(pawn.double_step).to be true
          end
        end
      end

      context 'when the pawn is not in starting position' do
        10.times do
          it 'prompts the user to enter a different position' do
            pawn.instance_variable_set(:@position, [random_position.first, (2..5).to_a.sample])
            legal_input = ('a'..'h').to_a[pawn.position.first] + (pawn.position.last + (player_index.zero? ? 1 : -1) + 1).to_s
            allow(pawn).to receive(:gets).and_return(double_step_position_input, legal_input)
            expect(pawn).to receive(:puts).with('Please enter a square for the pawn that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            pawn.move([])
          end
        end
      end
    end

    context 'when the next position is entered after a double-step' do
      10.times do
        it 'changes the double-step instance variable back to false' do
          pawn.instance_variable_set(:@double_step, true)
          pawn.instance_variable_set(:@position, [random_position.first, [3, 4][player_index]])
          legal_input = ('a'..'h').to_a[pawn.position.first] + (pawn.position.last + (player_index.zero? ? 1 : -1) + 1).to_s
          allow(pawn).to receive(:gets).and_return(legal_input)
          pawn.move([])
          expect(pawn.double_step).to be false
        end
      end
    end
  end
end
