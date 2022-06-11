require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
  end

  describe '#initialize' do
    before do
      allow(game).to receive(:puts)
    end

    let(:board) { game.instance_variable_get(:@board) }
    it 'sets up starting board with correct number of pieces for each side' do
      side_count = board.partition { |piece| piece.player_index.zero? }.map(&:size)
      expect(side_count).to eq([16, 16])
    end

    it 'sets up starting board with correct number of piece types' do
      piece_counts = [Pawn, Rook, Knight, Bishop, Queen, King].map do |type|
        board.count { |piece| piece.class == type }
      end
      expect(piece_counts).to eq([16, 4, 4, 4, 2, 2])
    end

    it 'sets up starting board with correct positions' do
      correct_positions = [0, 1, 6, 7].map do |vert_dir|
        (0..7).map { |horiz_dir| [horiz_dir, vert_dir] }
      end.flatten(1).sort
      positions = board.map(&:position).sort
      expect(positions).to eq(correct_positions)
    end
  end

  describe '#play' do
    before do
      allow(game).to receive(:display_board)
      allow(game).to receive(:display_check_state)
      allow(game).to receive(:player_action)
    end

    context 'when the game is over' do
      it 'does not execute the loop' do
        allow(game).to receive(:display_mate_state)
        game.instance_variable_set(:@game_over, true)
        expect(game).not_to receive(:display_board)
        expect(game).not_to receive(:display_check_state)
        expect(game).not_to receive(:player_action)
        expect(game).not_to receive(:display_mate_state)
        game.play
      end
    end

    context 'when the game is over after a random number of loops' do
      10.times do
        it 'executes the loop the corresponding number of times' do
          loops = rand(1..100)
          call_count = 0
          allow(game).to receive(:display_mate_state) do
            call_count += 1
            game.instance_variable_set(:@game_over, true) if call_count == loops
          end
          expect(game).to receive(:display_board).exactly(loops).times
          expect(game).to receive(:display_check_state).exactly(loops).times
          expect(game).to receive(:player_action).exactly(loops).times
          expect(game).to receive(:display_mate_state).exactly(loops).times
          game.play
        end
      end
    end
  end

  describe '#display_check_state' do
    let(:checked_player_index) { rand(2) }
    let(:checked_player) { [white_player, black_player][checked_player_index] }
    let(:checking_player) { [white_player, black_player][checked_player_index ^ 1] }
    let(:king_to_check) { instance_double(King, player_index: checked_player_index, position: Array.new(2) { rand(8) }) }
    let(:check_message_reg) { Regexp.new("#{checking_player.color} gives check to #{checked_player.color}.") }

    before do
      allow(King).to receive(:new).with(checked_player_index, anything).and_return(king_to_check)
      allow(king_to_check).to receive(:is_a?).with(King).and_return(true)
      allow(King).to receive(:new).with(checked_player_index ^ 1, anything).and_call_original
      allow(game).to receive(:puts)
      game.instance_variable_set(:@curr_player_index, checked_player_index)
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

  describe '#display_mate_state' do
    let(:mated_player_index) { rand(2) }
    let(:mated_player) { [white_player, black_player][mated_player_index] }
    let(:mating_player) { [white_player, black_player][mated_player_index ^ 1] }
    let(:king_to_mate) { instance_double(King, player_index: mated_player_index, position: Array.new(2) { rand(8) }) }

    before do
      allow(King).to receive(:new).with(mated_player_index, anything).and_return(king_to_mate)
      allow(king_to_mate).to receive(:is_a?).with(King).and_return(true)
      allow(King).to receive(:new).with(mated_player_index ^ 1, anything).and_call_original
      allow(game).to receive(:puts)
      allow(game).to receive(:display_board)
      game.instance_variable_set(:@curr_player_index, mated_player_index)
      game.instance_variable_get(:@board).each do |piece|
        allow(piece).to receive(:legal_next_positions).and_return([])
      end
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
        allow(King).to receive(:new).with(mated_player_index, anything).and_return(king_to_mate)
        allow(king_to_mate).to receive(:is_a?).with(King).and_return(true)
        allow(king_to_mate).to receive(:checked?).and_return([true, false].sample)
        allow(King).to receive(:new).with(mated_player_index ^ 1, anything).and_call_original
        allow(game).to receive(:puts)
        allow(game).to receive(:display_board)
        game.instance_variable_set(:@curr_player_index, mated_player_index)
        game.instance_variable_get(:@board).each do |piece|
          allow(piece).to receive(:legal_next_positions).and_return([ Array.new(2) { rand(8) }])
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
