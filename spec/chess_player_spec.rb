# frozen_string_literal: true

require 'yaml'
require_relative '../lib/chess_player.rb'
describe Player do
  describe '::from_yaml' do
    10.times do
      it 'creates a player using data from the given string' do
        saved_player_index = rand(2)
        saved_name = rand(100).to_s + ('A'..'Z').to_a.sample
        saved_player_string = YAML.dump('player_index' => saved_player_index,
                                        'name' => saved_name)

        player = described_class.from_yaml(saved_player_string)
        expect(player.player_index).to eq(saved_player_index)
        expect(player.name).to eq(saved_name)
      end
    end
  end
end
