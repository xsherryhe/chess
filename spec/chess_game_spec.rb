require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }

  before do
    allow(Player).to receive(:new).and_return(instance_double(Player, player_index: 0),
                                              instance_double(Player, player_index: 1))
    allow(game).to receive(:puts)
  end

  describe '#initialize' do
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
end
