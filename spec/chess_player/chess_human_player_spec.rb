require_relative '../../lib/chess_player.rb'
require_relative '../../lib/chess_game.rb'

describe HumanPlayer do
  let(:player_index) { rand(2) }
  let(:name) { rand(100).to_s }
  subject(:player) { described_class.new(player_index, name) }

  before do
    allow(player).to receive(:puts)
  end

  describe '#initialize' do
    context 'when the name argument is not provided' do
      subject(:no_name_player) { described_class.new(player_index) }

      before do
        allow_any_instance_of(Object).to receive(:puts)
        allow_any_instance_of(Object).to receive(:gets).and_return(name)
      end

      10.times do
        it 'prompts the user for a player name' do
          expect_any_instance_of(Object).to receive(:puts).with(/please enter your name/)
          no_name_player
        end

        it 'sets the name variable to user input' do
          player_name = no_name_player.name
          expect(player_name).to eq(name)
        end
      end
    end
  end

  describe '#select_action' do
    let(:target_piece_position) { Array.new(2) { rand(8) } }
    let(:piece_next_position) do
      loop do
        pos = Array.new(2) { rand(8) }
        return pos unless pos == target_piece_position
      end
    end
    let(:target_piece) { instance_double(Piece, player_index: player_index, position: target_piece_position) }
    let(:board) { [target_piece] }
    let(:random_move_num) { rand(100) }
    let(:game) { instance_double(Game, board: board, move_num: random_move_num) }
    let(:move_input) do
      [('a'..'h').to_a[target_piece_position.first] + (target_piece_position.last + 1).to_s,
       ('a'..'h').to_a[piece_next_position.first] + (piece_next_position.last + 1).to_s]
        .join(['to', 'TO', ' to ', ' TO '].sample)
    end

    before do
      allow(target_piece).to receive(:legal_next_positions).and_return([piece_next_position])
      allow(target_piece).to receive(:illegal_check_next_positions).and_return([])
      allow(game).to receive(:can_castle?).and_return(false)
      allow(player).to receive(:gets).and_return(move_input)
    end

    10.times do
      it 'prompts the player for an input to determine their next action' do
        prompt_reg = Regexp.new("#{name}: Please enter the move you wish to make.+\\r\\n\\(Or enter the word MENU to view other game options\\.\\)")
        expect(player).to receive(:puts).with(prompt_reg)
        player.select_action(game)
      end
    end

    context 'when a standard move input is entered' do
      context 'when an input with the position of a player piece and a legal next position for the piece are entered' do
        10.times do
          it 'returns the player piece and the next position for the piece' do
            action = player.select_action(game)
            expect(action).to eq([target_piece, piece_next_position])
          end
        end
      end

      context 'while an input with the position of a square without a player piece is entered' do
        let(:empty_position) do
          loop do
            pos = Array.new(2) { rand(8) }
            unless [target_piece_position, piece_next_position].include?(pos)
              return pos
            end
          end
        end
        let(:empty_piece_position_input) do
          [('a'..'h').to_a[empty_position.first] + (empty_position.last + 1).to_s,
           ('a'..'h').to_a[piece_next_position.first] + (piece_next_position.last + 1).to_s]
            .join(['to', 'TO', ' to ', ' TO '].sample)
        end

        10.times do
          it 'prompts the player to enter a position until a valid position is entered' do
            invalid_count = rand(1..100)
            call_count = 0
            allow(player).to receive(:gets) do
              call_count += 1
              call_count == invalid_count + 1 ? move_input : empty_piece_position_input
            end
            error_reg = /You don't have a piece on that square!\r\n.+Please enter the move you wish to make/
            expect(player).to receive(:puts).with(error_reg).exactly(invalid_count).times
            player.select_action(game)
          end
        end
      end

      context 'while an input with the position of a player piece and an illegal next position for the piece are entered' do
        let(:illegal_next_position) do
          loop do
            pos = Array.new(2) { rand(8) }
            unless [target_piece_position, piece_next_position].include?(pos)
              return pos
            end
          end
        end
        let(:illegal_move_input) do
          [('a'..'h').to_a[target_piece_position.first] + (target_piece_position.last + 1).to_s,
           ('a'..'h').to_a[illegal_next_position.first] + (illegal_next_position.last + 1).to_s]
            .join(['to', 'TO', ' to ', ' TO '].sample)
        end

        10.times do
          it 'prompts the player to enter a position until a valid position is entered' do
            invalid_count = rand(1..100)
            call_count = 0
            allow(player).to receive(:gets) do
              call_count += 1
              call_count == invalid_count + 1 ? move_input : illegal_move_input
            end
            error_reg = /Illegal move!\r\n.+Please enter the move you wish to make/
            expect(player).to receive(:puts).with(error_reg).exactly(invalid_count).times
            player.select_action(game)
          end
        end

        context 'when the illegal next position would leave the king in check' do
          10.times do
            it 'prompts the user with a message about leaving the king in check until a valid position is entered' do
              allow(target_piece).to receive(:illegal_check_next_positions).and_return([illegal_next_position])
              invalid_count = rand(1..100)
              call_count = 0
              allow(player).to receive(:gets) do
                call_count += 1
                call_count == invalid_count + 1 ? move_input : illegal_move_input
              end
              error_reg = /Illegal move! This move would leave your king in check\.\r\n.+Please enter the move you wish to make/
              expect(player).to receive(:puts).with(error_reg).exactly(invalid_count).times
              player.select_action(game)
            end
          end
        end
      end
    end

    context 'when a castling move is possible' do
      before do
        allow(game).to receive(:can_castle?).and_return(true)
      end

      it 'prompts the player with a castling-specific instruction' do
        expect(player).to receive(:puts).with(/Castling is also available\. Enter the word CASTLE to make a castling move\./)
        player.select_action(game)
      end

      it 'still allows other move inputs' do
        action = player.select_action(game)
        expect(action).to eq([target_piece, piece_next_position])
      end

      context 'when the string "castle" is entered' do
        10.times do
          it 'returns the inputted string' do
            allow(player).to receive(:gets).and_return(%w[castle CASTLE].sample)
            action = player.select_action(game)
            expect(action).to match(/castle/i)
          end
        end
      end
    end

    context 'while the string "castle" is entered and a castling move is not possible' do
      10.times do
        it 'prompts the user to enter a different input until a valid input is entered' do
          castle_input_count = rand(100)
          call_count = 0
          allow(player).to receive(:gets) do
            call_count += 1
            call_count == castle_input_count + 1 ? move_input : 'castle'
          end
          error_reg = /Invalid input!\r\n.+Please enter the move you wish to make.+\(Or enter the word MENU to view other game options\.\)/
          expect(player).to receive(:puts).with(error_reg).exactly(castle_input_count).times
          player.select_action(game)
        end
      end
    end

    context 'when the string "menu" is entered' do
      10.times do
        it 'returns the inputted string' do
          allow(player).to receive(:gets).and_return(%w[menu MENU].sample)
          action = player.select_action(game)
          expect(action).to match(/menu/i)
        end
      end
    end

    context 'while an invalid input is entered' do
      10.times do
        it 'prompts the player to enter an input until a valid input is entered' do
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ["I don't know", 'Z1', 'A9', 'Y1 to A8', 'B1 to A9', 'f23', 'b', '[0, 1]', '[1, 1] to [0, 1]', '20', 'no', ':help', '(']
          allow(player).to receive(:gets) do
            call_count += 1
            call_count == invalid_count + 1 ? move_input : invalid_inputs.sample
          end
          error_reg = /Invalid input!\r\n.+Please enter the move you wish to make.+\(Or enter the word MENU to view other game options\.\)/
          expect(player).to receive(:puts).with(error_reg).exactly(invalid_count).times
          player.select_action(game)
        end
      end
    end
  end

  describe '#select_rook' do
    let(:player_rook1) { instance_double(Rook, position: [0, 7 * player_index]) }
    let(:player_rook2) { instance_double(Rook, position: [7, 7 * player_index]) }
    let(:random_move_num) { rand(100) }
    let(:game) { instance_double(Game, move_num: random_move_num) }

    context 'when a castling move is possible with one rook' do
      let(:rooks) { [[player_rook1, player_rook2].sample] }

      it 'returns the rook that can be castled with' do
        rook = player.select_rook(rooks, game)
        expect(rooks).to include(rook)
      end
    end

    context 'when a castling move is possible with both rooks' do
      let(:rooks) { [player_rook1, player_rook2] }
      let(:player_rook) { rooks.sample }
      let(:rook_position_inputs) do
        [[0, 7 * player_index], [7, 7 * player_index]].map do |pos|
          ('a'..'h').to_a[pos.first] + (pos.last + 1).to_s
        end
      end
      let(:rook_position_input) do
        rook_position_inputs[rooks.index(player_rook)]
      end

      before do
        allow(player).to receive(:gets).and_return(rook_position_input)
      end

      10.times do
        it 'displays a list of rooks to castle and prompts the player to select a rook position' do
          rook_message_reg = Regexp.new(
            "Your king can castle with the following rooks at: #{rook_position_inputs.map(&:upcase).join(', ')}" \
            "\r\nPlease enter the square of the rook that you would like your king to castle with"
          )
          expect(player).to receive(:puts).with(rook_message_reg)
          player.select_rook(rooks, game)
        end
      end

      context 'when a valid rook position is entered' do
        10.times do
          it 'returns the corresponding rook' do
            rook = player.select_rook(rooks, game)
            expect(rook).to eq(player_rook)
          end
        end
      end

      context 'while an invalid rook position is entered' do
        let(:illegal_rook_position_input) do
          loop do
            input = ('a'..'h').to_a.sample + (1..8).to_a.sample.to_s
            return input unless rook_position_inputs.include?(input)
          end
        end

        10.times do
          it 'prompts the player to enter a rook position until a valid rook position is entered' do
            illegal_inputs = rand(100)
            call_count = 0
            allow(player).to receive(:gets) do
              call_count += 1
              call_count == illegal_inputs + 1 ? rook_position_input : illegal_rook_position_input
            end
            expect(player)
              .to receive(:puts)
              .with('Invalid square! Please enter the square of a valid rook to castle with. Please use the format LETTER + NUMBER (e.g., "A1").')
              .exactly(illegal_inputs).times
            player.select_rook(rooks, game)
          end
        end
      end
    end
  end

  describe '#select_promote_class' do
    let(:class_input) do
      [[%w[knight KNIGHT].sample, Knight],
       [%w[rook ROOK].sample, Rook],
       [%w[bishop BISHOP].sample, Bishop],
       [%w[queen QUEEN].sample, Queen]].sample
    end

    before do
      allow(player).to receive(:gets).and_return(class_input.first)
    end

    it 'prompts the player to select a class to promote the pawn' do
      expect(player).to receive(:puts).with(/Please enter the piece type to promote your pawn to:/)
      player.select_promote_class
    end

    context 'when a valid promotion class input is entered' do
      10.times do
        it 'returns the corresponding class' do
          promote_class = player.select_promote_class
          expect(promote_class).to eq(class_input.last)
        end
      end
    end

    context 'while an invalid input for pawn promotion is entered' do
      10.times do
        it 'prompts the player to enter a class to promote the pawn until a valid input is entered' do
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ['pawn', 'KING', "I don't know", 'menu', '20', 'b', '[0, 1]', ':help', '(']
          allow(player).to receive(:gets) do
            call_count += 1
            call_count == invalid_count + 1 ? class_input.first : invalid_inputs.sample
          end
          expect(player).to receive(:puts).with(/Invalid input! Please enter the piece type to promote your pawn to/).exactly(invalid_count).times
          player.select_promote_class
        end
      end
    end
  end

  describe '#claim_draw?' do
    let(:input) { %w[y Y yes YES n N no NO].sample }

    before do
      allow(player).to receive(:gets).and_return(input)
    end

    10.times do
      it 'prompts the player to confirm or refuse claiming a draw' do
        expect(player).to receive(:puts).with("#{name}, do you wish to claim a draw?")
        player.claim_draw?
      end

      it 'returns the input' do
        claim_draw = player.claim_draw?
        expect(claim_draw).to eq(input)
      end
    end
  end

  describe '#accept_draw?' do
    let(:input) { %w[y Y yes YES n N no NO].sample }

    before do
      allow(player).to receive(:gets).and_return(input)
    end

    10.times do
      it 'prompts the player to confirm or refuse to accept a draw' do
        expect(player).to receive(:puts).with("#{name}, do you accept the proposal of draw?")
        player.accept_draw?
      end

      it 'returns the input' do
        accept_draw = player.accept_draw?
        expect(accept_draw).to eq(input)
      end
    end
  end
end
