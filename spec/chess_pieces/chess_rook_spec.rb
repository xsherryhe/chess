require_relative '../../lib/chess_pieces/chess_rook.rb'

describe Rook do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:rook) { described_class.new(player_index, random_position) }

  describe '#move' do
    let(:legal_position) do
      loop do
        change = rand(1..7) * [1, -1].sample
        position = [[random_position.first + change, random_position.last],
                    [random_position.first, random_position.last + change]]
                   .sample
        return position if position.all? { |dir| dir.between?(0, 7) }
      end
    end
    let(:legal_position_input) do
      ('a'..'h').to_a[legal_position.first] + (legal_position.last + 1).to_s
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while position.first == random_position.first ||
            position.last == random_position.last
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:illegal_position_input) do
      ('a'..'h').to_a[illegal_position.first] + (illegal_position.last + 1).to_s
    end

    before do
      allow(rook).to receive(:puts)
    end

    context 'when a legal position is entered' do
      before do
        allow(rook).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(rook).to receive(:puts).with('Please enter the square to move the rook, using the format LETTER + NUMBER (e.g., "A1").')
          rook.move([])
        end

        it "changes the rook's position to the new position" do
          rook.move([])
          expect(rook.position).to eq(legal_position)
        end
      end
    end

    context 'while an illegal position is entered' do
      10.times do
        it 'prompts the user to enter a position until a legal position is entered' do
          illegal_inputs = rand(100)
          call_count = 0
          allow(rook).to receive(:gets) do
            call_count += 1
            call_count == illegal_inputs + 1 ? legal_position_input : illegal_position_input
          end
          expect(rook)
            .to receive(:puts)
            .with('Please enter a square for the rook that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            .exactly(illegal_inputs).times
          rook.move([])
        end
      end
    end

    context 'when there is a piece in the path of the rook' do
      let(:opponent_position) do
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
      let(:blocking_piece) { instance_double(Piece, position: opponent_position) }
      let(:board) { [blocking_piece] }
      let(:before_position) do
        [random_position.first + (opponent_position.first <=> random_position.first),
         random_position.last + (opponent_position.last <=> random_position.last)]
      end
      let(:before_position_input) do
        ('a'..'h').to_a[before_position.first] + (before_position.last + 1).to_s
      end

      context 'when positions in the path are entered' do
        let(:after_position) do
          [opponent_position.first + (opponent_position.first <=> random_position.first),
           opponent_position.last + (opponent_position.last <=> random_position.last)]
        end
        let(:after_position_input) do
          ('a'..'h').to_a[after_position.first] + (after_position.last + 1).to_s
        end

        before do
          allow(blocking_piece).to receive(:player_index).and_return(rand(2))
          allow(rook).to receive(:gets).and_return(after_position_input, before_position_input)
        end

        context 'when a position after the occupied position is entered' do
          10.times do
            it 'prompts the user to enter a different position' do
              expect(rook).to receive(:puts).with('Please enter a square for the rook that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
              rook.move(board)
            end
          end
        end

        context 'when a position before the occupied position is entered' do
          10.times do
            it "allows the rook's position to be changed" do
              rook.move(board)
              expect(rook.position).to eq(before_position)
            end
          end
        end
      end

      context 'when the occupied position is entered' do
        let(:opponent_position_input) do
          ('a'..'h').to_a[opponent_position.first] + (opponent_position.last + 1).to_s
        end

        context "when the piece is the opponent's" do
          10.times do
            it "allows the rook's position to be changed" do
              allow(blocking_piece).to receive(:player_index).and_return(player_index ^ 1)
              allow(rook).to receive(:gets).and_return(opponent_position_input)
              rook.move(board)
              expect(rook.position).to eq(opponent_position)
            end
          end
        end

        context "when the piece is the player's own" do
          10.times do
            it 'prompts the user to enter a different position' do
              allow(blocking_piece).to receive(:player_index).and_return(player_index)
              allow(rook).to receive(:gets).and_return(opponent_position_input, before_position_input)
              expect(rook).to receive(:puts).with('Please enter a square for the rook that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
              rook.move(board)
            end
          end
        end
      end
    end
  end
end
