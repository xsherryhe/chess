require_relative '../../lib/chess_pieces/chess_bishop.rb'

describe Bishop do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:bishop) { described_class.new(player_index, random_position) }

  describe '#move' do
    let(:legal_position) do
      loop do
        distance = rand(1..7)
        position = [random_position.first + distance * [1, -1].sample,
                    random_position.last + distance * [1, -1].sample]
        return position if position.all? { |dir| dir.between?(0, 7) }
      end
    end
    let(:legal_position_input) do
      ('a'..'h').to_a[legal_position.first] + (legal_position.last + 1).to_s
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while (position.first - random_position.first).abs ==
            (position.last - random_position.last).abs
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:illegal_position_input) do
      ('a'..'h').to_a[illegal_position.first] + (illegal_position.last + 1).to_s
    end

    before do
      allow(bishop).to receive(:puts)
    end

    context 'when a legal position is entered' do
      before do
        allow(bishop).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(bishop).to receive(:puts).with('Please enter the square to move the bishop, using the format LETTER + NUMBER (e.g., "A1").')
          bishop.move([])
        end

        it "changes the bishop's position to the new position" do
          bishop.move([])
          expect(bishop.position).to eq(legal_position)
        end
      end
    end

    context 'while an illegal position is entered' do
      10.times do
        it 'prompts the user to enter a position until a legal position is entered' do
          illegal_inputs = rand(100)
          call_count = 0
          allow(bishop).to receive(:gets) do
            call_count += 1
            call_count == illegal_inputs + 1 ? legal_position_input : illegal_position_input
          end
          expect(bishop)
            .to receive(:puts)
            .with('Please enter a square for the bishop that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            .exactly(illegal_inputs).times
          bishop.move([])
        end
      end
    end

    context 'when there is a piece in the path of the bishop' do
      context 'when a position before the occupied position is entered' do
        it "allows the pawn's position to be changed" do
        end
      end

      context 'when a position beyond the occupied position is entered' do
        it 'prompts the user to enter a different position' do
        end
      end

      context "when the occupied position is entered and the piece is the opponent's" do
        it "allows the pawn's position to be changed" do
        end
      end

      context "when the occupied position is entered and the piece is the player's own" do
        it 'prompts the user to enter a different position' do
        end
      end
    end
  end
end
