require_relative '../../lib/chess_pieces/chess_knight.rb'
require_relative '../../lib/chess_pieces/chess_king.rb'

describe Knight do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:knight) { described_class.new(player_index, random_position) }
  let(:random_move_num) { rand(50) }

  describe '#move' do
    let(:legal_position) do
      moves = [[-1, -2], [-1, 2], [1, -2], [1, 2], [-2, -1], [-2, 1], [2, -1], [2, 1]]
      loop do
        position = moves.sample.map.with_index { |change, i| random_position[i] + change }
        return position if position.all? { |dir| dir.between?(0, 7) }
      end
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
    let(:illegal_position_message) { 'Illegal move! Please enter a square for the knight that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").' }

    before do
      allow(knight).to receive(:puts)
      allow(knight).to receive(:player_king).and_return(instance_double(King, player_index: player_index, position: [-1, -1], checked?: false))
    end

    context 'when a legal position is entered' do
      before do
        allow(knight).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(knight).to receive(:puts).with(/Please enter the square to move the knight/)
          knight.move([], random_move_num)
        end

        it "changes the knight's position to the new position" do
          knight.move([], random_move_num)
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
            .with(illegal_position_message)
            .exactly(illegal_inputs).times
          knight.move([], random_move_num)
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

      let(:blocking_position_input) do
        ('a'..'h').to_a[blocking_position.first] + (blocking_position.last + 1).to_s
      end

      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [blocking_piece] }

      context "when the piece is the opponent's" do
        10.times do
          it "allows the knight's position to be changed" do
            allow(blocking_piece).to receive(:player_index).and_return(player_index ^ 1)
            allow(knight).to receive(:gets).and_return(blocking_position_input)
            knight.move(board, random_move_num)
            expect(knight.position).to eq(blocking_position)
          end
        end
      end

      context "when the piece is the player's own" do
        10.times do
          it 'prompts the user to enter a different position' do
            allow(blocking_piece).to receive(:player_index).and_return(player_index)
            allow(knight).to receive(:gets).and_return(blocking_position_input, legal_position_input)
            expect(knight).to receive(:puts).with(illegal_position_message)
            knight.move(board, random_move_num)
          end
        end
      end
    end
  end
end
