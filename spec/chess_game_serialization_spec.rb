# frozen_string_literal: true

require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }
  let(:players) { game.instance_variable_get(:@players) }
  let(:board) { game.instance_variable_get(:@board) }
  let(:mock_save_dir) { "#{__dir__}/mock_saves" }
  let(:mock_save_record) { "#{__dir__}/mock_saves/mock_save_record.txt" }
  let(:existing_save_name) { rand(20).to_s + %w[a A].sample }

  def clear_save_record
    File.write(mock_save_record, ' ')
  end

  def clear_save_dir
    Dir.foreach(mock_save_dir) do |file|
      unless %w[. .. mock_save_record.txt].include?(file)
        File.delete("#{mock_save_dir}/#{file}")
      end
    end
  end

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
    allow(game).to receive(:puts)
    allow(game).to receive(:save_dir).and_return(mock_save_dir)
    allow(game).to receive(:save_record).and_return(mock_save_record)
    clear_save_record
    clear_save_dir
    File.open(mock_save_record, 'w') do |record_file|
      20.times { |i| record_file.puts("#{i}a") }
    end
    20.times { |i| File.write("#{mock_save_dir}/#{i}a.yaml", '') }
  end

  after do
    clear_save_record
    clear_save_dir
  end

  describe '#update_from_yaml' do
    10.times do
      it 'updates the game with data from the given file' do
        saved_game = described_class.new

        saved_game_players = [instance_double(Player, name: rand(100).to_s, player_index: 0),
                              instance_double(Player, name: rand(100).to_s, player_index: 1)]
        saved_game_players.each do |player|
          allow(player).to receive(:to_yaml).and_return(YAML.dump('player_index' => player.player_index, 'name' => player.name))
        end
        allow(Player).to receive(:from_yaml) do |string|
          data = YAML.safe_load(string)
          instance_double(Player, name: data['name'], player_index: data['player_index'])
        end
        saved_game.instance_variable_set(:@players, saved_game_players)

        saved_game_board = Array.new(rand(32)) do
          [King, Queen, Rook, Bishop, Knight, Pawn].sample.new(rand(2), Array.new(2) { rand(8) })
        end
        saved_game.instance_variable_set(:@board, saved_game_board)

        saved_file_name = "#{mock_save_dir}/#{existing_save_name.downcase}.yaml"
        File.write(saved_file_name, saved_game.to_yaml)

        def instance_vals(piece)
          piece.instance_variables.map { |var| piece.instance_variable_get(var) }
        end

        game.update_from_yaml(saved_file_name)

        board.each_with_index do |piece, i|
          vals = instance_vals(piece)
          saved_vals = instance_vals(saved_game_board[i])
          expect(vals).to eq(saved_vals)
        end
        players.each_with_index do |player, i|
          saved_player = saved_game_players[i]
          vals = [player.name, player.player_index]
          saved_vals = [saved_player.name, saved_player.player_index]
          expect(vals).to eq(saved_vals)
        end
      end
    end
  end

  describe '::from_yaml' do
    let(:saved_file_name) { "#{mock_save_dir}/#{existing_save_name.downcase}.yaml" }
    let(:game) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(game)
      allow(game).to receive(:update_from_yaml)
    end

    it 'creates a new game with a custom setup' do
      expect(described_class).to receive(:new).with(true)
      described_class.from_yaml(saved_file_name)
    end

    it 'sends an #update_from_yaml message with the given file to the game' do
      expect(game).to receive(:update_from_yaml).with(saved_file_name)
      described_class.from_yaml(saved_file_name)
    end
  end
end
