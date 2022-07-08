require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }
  let(:board) { game.instance_variable_get(:@board) }

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
    allow(game).to receive(:system)
    allow(game).to receive(:display_board)
    allow(game).to receive(:puts)
  end

  describe '#display_check_state' do
    let(:checked_player_index) { rand(2) }
    let(:checked_player) { [white_player, black_player][checked_player_index] }
    let(:checking_player) { [white_player, black_player][checked_player_index ^ 1] }
    let(:king_to_check) { instance_double(King, player_index: checked_player_index, position: Array.new(2) { rand(8) }) }
    let(:checked_board) do
      new_board = board.reject { |piece| piece.is_a?(King) && piece.player_index == checked_player_index }
      new_board << king_to_check
    end
    let(:check_message_reg) { Regexp.new("#{checking_player.color} gives check to #{checked_player.color}.") }

    before do
      allow(king_to_check).to receive(:is_a?).with(King).and_return(true)
      allow(king_to_check).to receive(:to_yaml).and_return('')
      game.instance_variable_set(:@curr_player_index, checked_player_index)
      game.instance_variable_set(:@board, checked_board)
      allow(game).to receive(:gets).and_return('')
    end

    context 'when a player checks their opponent' do
      10.times do
        it 'outputs a check message' do
          allow(king_to_check).to receive(:checked?).and_return(true)
          expect(game).to receive(:puts).with(check_message_reg)
          game.display_check_state
        end
      end
    end

    context 'when a player does not check their opponent' do
      10.times do
        it 'does not output a check message' do
          allow(king_to_check).to receive(:checked?).and_return(false)
          expect(game).not_to receive(:puts).with(check_message_reg)
          game.display_check_state
        end
      end
    end
  end

  describe '#display_draw_claim_state' do
    let(:game_history_position) do
      Array.new(rand(50)) { (('A'..'Z').to_a + ('a'..'z').to_a).sample }.join
    end

    before do
      game.instance_variable_set(:@history, [game_history_position] * rand(5))
      game.instance_variable_set(:@idle_moves, rand(200))
      allow(game).to receive(:gets).and_return(%w[YES yes Y y].sample)
    end

    context 'when the game history includes a repetition of positions at least three times' do
      before do
        game.instance_variable_set(:@history, [game_history_position] * rand(3..30))
      end

      10.times do
        it 'displays a repetition of positions message and prompts the user to claim a draw' do
          expect(game).to receive(:puts).with(/The same position with the same player to move has been repeated at least 3 times in the game/)
          expect(game).to receive(:puts).with(/do you wish to claim a draw\?/)
          game.display_draw_claim_state
        end
      end

      context 'when the user confirms that they wish to claim a draw' do
        10.times do
          it 'outputs a draw message' do
            expect(game).to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'ends the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).to be true
          end
        end
      end

      context 'when the user does not confirm that they wish to claim a draw' do
        before do
          allow(game).to receive(:gets).and_return(['n', 'N', 'no', 'NO', 'yesterday', ''].sample)
        end

        10.times do
          it 'does not output a draw message' do
            expect(game).not_to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'does not end the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).not_to be true
          end
        end
      end
    end

    context 'when there have been 50 moves by both players without a piece captured or pawn move' do
      before do
        game.instance_variable_set(:@idle_moves, rand(100..200))
      end

      10.times do
        it 'displays a 50 moves message and prompts the user to claim a draw' do
          expect(game).to receive(:puts).with(/there have been 50 consecutive moves of both players without any piece taken or any pawn move/i)
          expect(game).to receive(:puts).with(/do you wish to claim a draw\?/)
          game.display_draw_claim_state
        end
      end

      context 'when the user confirms that they wish to claim a draw' do
        10.times do
          it 'outputs a draw message' do
            expect(game).to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'ends the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).to be true
          end
        end
      end

      context 'when the user does not confirm that they wish to claim a draw' do
        before do
          allow(game).to receive(:gets).and_return(['n', 'N', 'no', 'NO', 'yesterday', ''].sample)
        end

        10.times do
          it 'does not output a draw message' do
            expect(game).not_to receive(:puts).with('The game ends in a draw.')
            game.display_draw_claim_state
          end

          it 'does not end the game' do
            game.display_draw_claim_state
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).not_to be true
          end
        end
      end
    end

    context 'when no conditions are fulfilled that allow a draw claim' do
      before do
        game.instance_variable_set(:@history, [game_history_position] * rand(3))
        game.instance_variable_set(:@idle_moves, rand(100))
      end

      10.times do
        it 'does not prompt the user to claim a draw' do
          expect(game).not_to receive(:puts).with(/do you wish to claim a draw\?/)
          game.display_draw_claim_state
        end
      end
    end
  end

  describe '#display_mate_state' do
    let(:mated_player_index) { rand(2) }
    let(:mated_player) { [white_player, black_player][mated_player_index] }
    let(:mating_player) { [white_player, black_player][mated_player_index ^ 1] }
    let(:king_to_mate) { instance_double(King, player_index: mated_player_index, position: Array.new(2) { rand(8) }) }
    let(:mated_board) do
      new_board = board.reject { |piece| piece.is_a?(King) && piece.player_index == mated_player_index }
      new_board << king_to_mate
      new_board.each do |piece|
        allow(piece).to receive(:legal_next_positions).and_return([])
      end
    end

    before do
      allow(king_to_mate).to receive(:is_a?).with(King).and_return(true)
      allow(king_to_mate).to receive(:to_yaml).and_return('')
      game.instance_variable_set(:@curr_player_index, mated_player_index)
      game.instance_variable_set(:@board, mated_board)
      allow(game).to receive(:gets).and_return('')
    end

    context 'when a player checkmates their opponent' do
      before do
        allow(king_to_mate).to receive(:checked?).and_return(true)
      end

      10.times do
        it 'outputs a checkmate and win game message' do
          checkmate_message_reg = Regexp.new("#{mating_player.color} gives checkmate to #{mated_player.color}. #{mating_player.name} has won the game!")
          expect(game).to receive(:puts).with(checkmate_message_reg)
          game.display_mate_state
        end

        it 'ends the game' do
          game.display_mate_state
          game_over = game.instance_variable_get(:@game_over)
          expect(game_over).to be true
        end
      end
    end

    context 'when the game is stalemated' do
      before do
        allow(king_to_mate).to receive(:checked?).and_return(false)
      end

      10.times do
        it 'outputs a stalemate and draw message' do
          stalemate_message_reg = Regexp.new("#{mated_player.color} gets a stalemate. The game is a draw.")
          expect(game).to receive(:puts).with(stalemate_message_reg)
          game.display_mate_state
        end

        it 'ends the game' do
          game.display_mate_state
          game_over = game.instance_variable_get(:@game_over)
          expect(game_over).to be true
        end
      end
    end

    context 'when the opponent still has legal moves' do
      before do
        allow(king_to_mate).to receive(:checked?).and_return([true, false].sample)
        game.instance_variable_get(:@board).each do |piece|
          allow(piece).to receive(:legal_next_positions).and_return([Array.new(2) { rand(8) }])
        end
      end

      10.times do
        it 'does not output a checkmate or stalemate message' do
          expect(game).not_to receive(:puts)
          game.display_mate_state
        end

        it 'does not end the game' do
          game.display_mate_state
          game_over = game.instance_variable_get(:@game_over)
          expect(game_over).not_to be true
        end
      end
    end
  end
end
