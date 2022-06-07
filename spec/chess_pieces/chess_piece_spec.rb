require_relative '../../lib/chess_pieces/chess_piece.rb'
describe Piece do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:piece) { described_class.new(player_index, random_position) }
  let(:random_move_num) { rand(50) }
  let(:legal_position) do
    loop do
      position = Array.new(2) { rand(8) }
      return position unless position == random_position
    end
  end
  let(:legal_position_input) do
    ('a'..'h').to_a[legal_position.first] + (legal_position.last + 1).to_s
  end

  before do
    allow(piece).to receive(:puts)
    piece.instance_variable_set(:@name, 'piece')
    piece.instance_variable_set(:@legal_next_positions, [legal_position])
    piece.instance_variable_set(:@illegal_check_next_positions, [])
  end

  describe '#move' do
    context 'while an invalid input is given' do
      10.times do
        it 'prompts the user to enter an input until a valid input is entered' do
          allow(piece).to receive(:update_next_positions)
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ['Z1', 'A8', 'f23', 'b', '[0, 1]', '75']
          allow(piece).to receive(:gets) do
            call_count += 1
            call_count == invalid_count + 1 ? legal_position_input : invalid_inputs.sample
          end
          expect(piece)
            .to receive(:puts)
            .with('Please enter a square for the piece that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            .exactly(invalid_count).times
          piece.move([], random_move_num)
        end
      end
    end
  end
end
