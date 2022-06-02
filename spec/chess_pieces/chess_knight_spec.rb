require_relative '../../lib/chess_pieces/chess_knight.rb'

describe Knight do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:knight) { described_class.new(player_index, random_position) }

  describe '#move' do
    let(:legal_position) do
      moves = [[-1, -2], [-1, 2], [1, -2], [1, 2], [-2, -1], [-2, 1], [2, -1], [2, 1]]
      position = moves.sample.map.with_index { |change, i| random_position[i] + change }
      until position.all? { |dir| dir.between?(0, 7) }
        position = moves.sample.map.with_index { |change, i| random_position[i] + change }
      end
      position
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
      allow(knight).to receive(:puts)
    end

    context 'when a legal position is entered' do
      before do
        allow(knight).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(knight).to receive(:puts).with('Please enter the square to move the knight, using the format LETTER + NUMBER (e.g., "A1").')
          knight.move([])
        end

        it "changes the knight's position to the new position" do
          knight.move([])
          expect(knight.position).to eq(legal_position)
        end
      end
    end

    context 'while an illegal position is entered' do
      10.times do
        it 'prompts the user to enter a position until a legal position is entered' do
          illegal_inputs = rand(100)
          call_count = 0
          allow(knight).to receive(:gets) do
            call_count += 1
            call_count == illegal_inputs + 1 ? legal_position_input : illegal_position_input
          end
          expect(knight)
            .to receive(:puts)
            .with('Please enter a square for the knight that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            .exactly(illegal_inputs).times
          knight.move([])
        end
      end
    end
  end
end
