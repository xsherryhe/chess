require_relative '../../lib/chess_pieces/chess_king.rb'
require_relative '../../lib/chess_pieces/chess_rook.rb'

describe King do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:king) { described_class.new(player_index, random_position) }
  let(:random_move_num) { rand(50) }

  describe '#move' do
    let(:legal_position) do
      loop do
        position = [random_position.first + [1, 0, -1].sample,
                    random_position.last + [1, 0, -1].sample]
        if position != random_position && position.all? { |dir| dir.between?(0, 7) }
          return position
        end
      end
    end
    let(:legal_position_input) do
      ('a'..'h').to_a[legal_position.first] + (legal_position.last + 1).to_s
    end
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while (position.first - random_position.first).abs <= 1 &&
            (position.last - random_position.last).abs <= 1
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:illegal_position_input) do
      ('a'..'h').to_a[illegal_position.first] + (illegal_position.last + 1).to_s
    end
    let(:illegal_position_message) { 'Illegal move! Please enter a square for the king that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").' }
    let(:board) { [king] }

    before do
      allow(king).to receive(:puts)
      allow(king).to receive(:can_castle?).and_return(false)
    end

    context 'when a legal position is entered' do
      before do
        allow(king).to receive(:gets).and_return(legal_position_input)
      end

      10.times do
        it 'prompts the user to enter a position' do
          expect(king).to receive(:puts).with(/Please enter the square to move the king/)
          king.move(board, random_move_num)
        end

        it "changes the king's position to the new position" do
          king.move(board, random_move_num)
          expect(king.position).to eq(legal_position)
        end
      end
    end

    context 'while an illegal position is entered' do
      10.times do
        it 'prompts the user to enter a position until a legal position is entered' do
          illegal_inputs = rand(100)
          call_count = 0
          allow(king).to receive(:gets) do
            call_count += 1
            call_count == illegal_inputs + 1 ? legal_position_input : illegal_position_input
          end
          expect(king)
            .to receive(:puts)
            .with(illegal_position_message)
            .exactly(illegal_inputs).times
          king.move(board, random_move_num)
        end
      end
    end

    context 'when there is a piece in the path of the king' do
      let(:blocking_position) do
        loop do
          position = [random_position.first + [1, 0, -1].sample,
                      random_position.last + [1, 0, -1].sample]
          if position != random_position &&
             position != legal_position &&
             position.all? { |dir| dir.between?(0, 7) }
            return position
          end
        end
      end

      let(:blocking_position_input) do
        ('a'..'h').to_a[blocking_position.first] + (blocking_position.last + 1).to_s
      end

      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [king, blocking_piece] }

      before do
        allow(blocking_piece).to receive(:is_a?).and_return([true, false].sample)
        allow(king).to receive(:checked?).and_return(false)
      end

      context "when the piece is the opponent's" do
        10.times do
          it "allows the king's position to be changed" do
            allow(blocking_piece).to receive(:player_index).and_return(player_index ^ 1)
            allow(king).to receive(:gets).and_return(blocking_position_input)
            king.move(board, random_move_num)
            expect(king.position).to eq(blocking_position)
          end
        end
      end

      context "when the piece is the player's own" do
        10.times do
          it 'prompts the user to enter a different position' do
            allow(blocking_piece).to receive(:player_index).and_return(player_index)
            allow(king).to receive(:gets).and_return(blocking_position_input, legal_position_input)
            expect(king).to receive(:puts).with(illegal_position_message)
            king.move(board, random_move_num)
          end
        end
      end
    end

    context 'when a castling move is possible for the king' do
      let(:rook1) { instance_double(Rook, player_index: player_index, position: [0, 7 * player_index], moved: false) }
      let(:rook2) { instance_double(Rook, player_index: player_index, position: [7, 7 * player_index], moved: false) }
      let(:board) { [rook1, rook2, king] }
      let(:legal_position_with_castle) do
        loop do
          position = [4 + [1, 0, -1].sample,
                      7 * player_index + [1, 0, -1].sample]
          if position != [4, 7 * player_index] && position.all? { |dir| dir.between?(0, 7) }
            return position
          end
        end
      end
      let(:legal_position_with_castle_input) do
        ('a'..'h').to_a[legal_position_with_castle.first] + (legal_position_with_castle.last + 1).to_s
      end

      before do
        king.position = [4, 7 * player_index]
        allow(king).to receive(:can_castle?).and_call_original
        [rook1, rook2].each do |rook|
          allow(rook).to receive(:is_a?).with(Rook).and_return(true)
          allow(rook).to receive(:is_a?).with(King).and_return(false)
          allow(rook).to receive(:position=)
        end
      end

      10.times do
        it 'prompts the user with a castling-specific instruction' do
          allow(king).to receive(:gets).and_return(legal_position_with_castle_input)
          expect(king).to receive(:puts).with(/Castling is also available for this king\. Please enter the word CASTLE to make a castling move\./)
          king.move(board, random_move_num)
        end

        it 'still allows other legal moves' do
          allow(king).to receive(:gets).and_return(legal_position_with_castle_input)
          king.move(board, random_move_num)
          expect(king.position).to eq(legal_position_with_castle)
        end
      end

      context 'when the user enters a CASTLE command' do
        let(:rook_position_inputs) do
          [[0, 7 * player_index], [7, 7 * player_index]].map do |pos|
            ('a'..'h').to_a[pos.first] + (pos.last + 1).to_s
          end
        end
        let(:rook_position_input) { rook_position_inputs.sample }

        10.times do
          it 'displays a list of rooks to castle and prompts the user to select a rook position' do
            allow(king).to receive(:gets).and_return(%w[castle CASTLE].sample, rook_position_input)
            rook_message_reg = Regexp.new(
              "Your king can castle with the following rooks at: #{rook_position_inputs.map(&:upcase).join(', ')}" \
              "\r\nPlease enter the square of the rook that you wish to castle with"
            )
            expect(king).to receive(:puts).with(rook_message_reg)
            king.move(board, random_move_num)
          end
        end

        context 'when a legal rook position is entered' do
          let(:rook) do
            [rook1, rook2].find do |r|
              col, row = rook_position_input.upcase.chars
              r.position == [col.ord - 65, row.to_i - 1]
            end
          end

          before do
            allow(king).to receive(:gets).and_return(%w[castle CASTLE].sample, rook_position_input)
          end

          10.times do
            it "changes the king's position appropriately" do
              new_king_position = [rook == rook1 ? 2 : 6, player_index * 7]
              king.move(board, random_move_num)
              expect(king.position).to eq(new_king_position)
            end

            it "sends a message to change the rook's position" do
              new_rook_position = [rook == rook1 ? 3 : 5, player_index * 7]
              expect(rook).to receive(:position=).with(new_rook_position)
              king.move(board, random_move_num)
            end
          end
        end

        context 'while an illegal rook position is entered' do
          let(:illegal_rook_position_input) do
            loop do
              input = ('a'..'h').to_a.sample + (0..7).to_a.sample.to_s
              return input unless rook_position_inputs.include?(input)
            end
          end

          10.times do
            it 'prompts the user to enter a rook position until an available rook position is entered' do
              illegal_inputs = rand(100)
              call_count = 0
              allow(king).to receive(:gets) do
                input = illegal_rook_position_input

                input = 'castle' if call_count.zero?
                input = rook_position_input if call_count == illegal_inputs + 1
                call_count += 1
                input
              end
              expect(king)
                .to receive(:puts)
                .with('Invalid square! Please enter the square of a valid rook to castle with. Please use the format LETTER + NUMBER (e.g., "A1").')
                .exactly(illegal_inputs).times
              king.move(board, random_move_num)
            end
          end
        end
      end
    end
  end

  describe '#checked?' do
    context "when an opponent's piece can check the player's king" do
      10.times do
        it 'returns true' do
          checking_piece = instance_double(Piece, player_index: player_index ^ 1, next_positions: [random_position])
          result = king.checked?(random_position, [checking_piece, king], random_move_num)
          expect(result).to be true
        end
      end
    end

    context "when no piece can check the player's king" do
      10.times do
        it 'returns false' do
          board = [instance_double(Piece, player_index: player_index, next_positions: [random_position]),
                   instance_double(Piece, player_index: player_index ^ 1, next_positions: []),
                   king]
          result = king.checked?(random_position, board, random_move_num)
          expect(result).to be false
        end
      end
    end
  end
end
