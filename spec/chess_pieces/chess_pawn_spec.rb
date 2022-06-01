require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe Pawn do
  let(:player_index) { rand(2) }
  let(:opponent_index) { player_index ^ 1 }
  let(:random_position) { [rand(8), rand(1..6)] }
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
  subject(:pawn) { described_class.new(player_index, random_position) }

  describe '#move' do
    before do
      allow(pawn).to receive(:puts)
    end

    context 'when a legal position is entered' do
      before do
        allow(pawn).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(pawn).to receive(:puts).with('Please enter the square to move the pawn.')
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
            .with('Please enter a square for the pawn that can be reached with a legal move.')
            .exactly(illegal_inputs).times
          pawn.move([])
        end
      end
    end

    context 'when a diagonal position is entered' do
      context 'when an opposing piece can be captured (is diagonal from the pawn)' do
        xit "allows the pawn's position to be changed" do
          
        end
      end

      context 'when an opposing pawn can be captured en passant' do
        xit "allows the pawn's position to be changed" do
        end
      end

      context 'when an opposing piece cannot be captured' do
        xit "does not allow the pawn's position to be changed" do
          
        end
      end
    end

    context 'when a double-step position is entered' do
      context 'when the pawn is in starting position' do
        xit "allows the pawn's position to be changed" do
        
        end
      end

      context 'when the pawn is not in starting position' do
        xit "does not allow the pawn's position to be changed" do
          
        end
      end
    end
  end
end
