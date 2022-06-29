# frozen_string_literal: true

Dir[File.expand_path('../../lib/chess_pieces/*.rb', __dir__)].sort.each do |file|
  require file
end

describe Piece do
  let(:player_index) { rand(2) }
  let(:random_position) do
    Array.new(2) { rand(8) }
  end
  subject(:piece) { described_class.new(player_index, random_position) }
  let(:legal_position) do
    loop do
      position = Array.new(2) { rand(8) }
      return position unless position == random_position
    end
  end

  describe '#move' do
    10.times do
      it "sets the piece's position to the given position" do
        piece.move(legal_position)
        expect(piece.position).to eq(legal_position)
      end
    end
=begin
    # move to game class
    context 'while an invalid input is entered' do
      10.times do
        it 'prompts the user to enter an input until a valid input is entered' do
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ['Z1', 'A9', 'f23', 'b', '[0, 1]', '75']
          allow(piece).to receive(:gets) do
            call_count += 1
            call_count == invalid_count + 1 ? legal_position_input : invalid_inputs.sample
          end
          expect(piece)
            .to receive(:puts)
            .with('Invalid input! Please enter a square for the piece that can be reached with a legal move. Please use the format LETTER + NUMBER (e.g., "A1").')
            .exactly(invalid_count).times
          piece.move([], random_move_num)
        end
      end
    end
=end
  end

  describe '::from_yaml' do
    10.times do
      it 'creates a piece using data about player index and position from the given string' do
        saved_class = [King, Queen, Bishop, Knight, Rook, Pawn].sample
        saved_piece_string = YAML.dump(
          { 'class' => saved_class.name,
            'data' => { 'player_index' => player_index,
                        'position' => random_position } }
        )

        piece = described_class.from_yaml(saved_piece_string)
        expect(piece).to be_a(saved_class)
        expect(piece.player_index).to eq(player_index)
        expect(piece.position).to eq(random_position)
      end
    end

    context 'when the piece has an additional @moved instance variable (king, rook)' do
      10.times do
        it 'creates a piece using data about the @moved instance variable from the given string' do
          saved_class = [King, Rook].sample
          saved_moved = [true, false].sample
          saved_piece_string = YAML.dump(
            { 'class' => saved_class.name,
              'data' => { 'player_index' => player_index,
                          'position' => random_position,
                          'moved' => saved_moved } }
          )

          piece = described_class.from_yaml(saved_piece_string)
          expect(piece.instance_variable_get(:@moved)).to eq(saved_moved)
        end
      end
    end

    context 'when the piece has additional @double_step and @en_passant variables (pawn)' do
      10.times do
        it 'creates a piece using data about the @double_step and @en_passant instance variables from the given string' do
          saved_double_step = [rand(50), false].sample
          saved_en_passant = [legal_position, false].sample
          saved_piece_string = YAML.dump(
            { 'class' => 'Pawn',
              'data' => { 'player_index' => player_index,
                          'position' => random_position,
                          'double_step' => saved_double_step,
                          'en_passant' => saved_en_passant } }
          )

          piece = described_class.from_yaml(saved_piece_string)
          expect(piece.instance_variable_get(:@double_step)).to eq(saved_double_step)
          expect(piece.instance_variable_get(:@en_passant)).to eq(saved_en_passant)
        end
      end
    end
  end
end
