require_relative '../../lib/chess_pieces/chess_king.rb'
require_relative '../../lib/chess_pieces/chess_rook.rb'
require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe King do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:king) { described_class.new(player_index, random_position) }
  let(:random_move_num) { rand(50) }
  let(:legal_position) do
    loop do
      position = [random_position.first + [1, 0, -1].sample,
                  random_position.last + [1, 0, -1].sample]
      if position != random_position && position.all? { |dir| dir.between?(0, 7) }
        return position
      end
    end
  end

  describe '#move' do
    it 'sets the moved variable to true' do
      king.move(legal_position)
      expect(king.moved).to be true
    end
  end

  describe '#legal_next_positions' do
    let(:illegal_position) do
      position = Array.new(2) { rand(8) }
      while (position.first - random_position.first).abs <= 1 &&
            (position.last - random_position.last).abs <= 1
        position = Array.new(2) { rand(8) }
      end
      position
    end
    let(:legal_positions) { king.legal_next_positions([king], random_move_num) }

    before do
      allow(king).to receive(:checked?).and_return(false)
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
        allow(king).to receive(:checked?).with(legal_position, any_args).and_return(true)
      end

      10.times do
        it 'excludes the position' do
          expect(legal_positions).not_to include(legal_position)
        end

        it 'includes the position in the illegal_check_next_positions variable' do
          legal_positions
          expect(king.illegal_check_next_positions).to include(legal_position)
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
      let(:blocking_piece) { instance_double(Piece, position: blocking_position) }
      let(:board) { [king, blocking_piece] }
      let(:legal_positions) { king.legal_next_positions(board, random_move_num) }

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

=begin
# move to chess castle spec

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
=end

  describe '#checked?' do
    before do
      allow(king).to receive(:checked?).and_call_original
    end
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
