# frozen_string_literal: true

require_relative '../lib/chess_game.rb'
describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }
  let(:players) { game.instance_variable_get(:@players) }
  let(:board) { game.instance_variable_get(:@board) }

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
    allow(game).to receive(:system)
    allow(game).to receive(:puts)
  end

  describe '#player_action' do
    let(:curr_player_index) { rand(2) }
    let(:curr_player) { [white_player, black_player][curr_player_index] }
    let(:opponent_player) { [white_player, black_player][curr_player_index ^ 1] }

    before do
      game.instance_variable_set(:@curr_player_index, curr_player_index)
      allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[back BACK 8].sample)
    end

    context 'when the word "menu" is entered' do
      10.times do
        it 'outputs a list of game menu options until the menu is closed' do
          loop_count = rand(1..100)
          call_count = 0
          allow(game).to receive(:select_menu_option) do
            call_count += 1
            if call_count == loop_count
              game.instance_variable_set(:@menu_done, true)
            end
          end
          expect(game).to receive(:puts).with(/Enter one of the following commands:/).exactly(loop_count).times
          game.player_action
        end
      end

      context 'when the word "back" or "8" is entered' do
        10.times do
          it 'exits the method' do
            game.player_action
          end
        end
      end

      context 'while the word "help" or "1" is entered' do
        10.times do
          it 'outputs chess instructions the corresponding number of times' do
            help_count = rand(100)
            call_count = 0
            allow(game).to receive(:gets) do
              call_count += 1
              if call_count == 1 then %w[menu MENU].sample
              elsif call_count == (help_count * 2) + 2 then %w[back BACK 8].sample
              elsif call_count.even? then %w[help HELP 1].sample
              else ''
              end
            end

            expect(game).to receive(:puts).with(/Chess is a board game with two players/).exactly(help_count).times
            game.player_action
          end
        end
      end

      context 'when the word "resign" or "2" is entered' do
        before do
          allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[resign RESIGN 2].sample, %w[y Y yes YES].sample)
        end

        10.times do
          it 'outputs a warning to player' do
            expect(game).to receive(:puts).with("WARNING: This will end the game.\r\nAre you sure you wish to resign the game to your opponent? (Y/N)")
            game.player_action
          end
        end

        context 'when the player confirms that they wish to resign' do
          10.times do
            it 'outputs an opponent win game message' do
              expect(game).to receive(:puts).with("#{opponent_player.name} has won the game!")
              game.player_action
            end

            it 'ends the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).to be true
            end
          end
        end

        context 'when the player does not confirm that they wish to resign' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[resign RESIGN 2].sample, ['n', 'N', 'no', 'NO', 'yesterday', ''].sample, 'back')
          end

          10.times do
            it 'does not output an opponent win game message' do
              expect(game).not_to receive(:puts).with("#{opponent_player.name} has won the game!")
              game.player_action
            end

            it 'does not end the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).not_to be true
            end
          end
        end
      end

      context 'when the word "draw" or "3" is entered' do
        before do
          allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[draw DRAW 3].sample, %w[y Y yes YES].sample)
        end

        10.times do
          it 'prompts the opponent to accept or decline the draw' do
            expect(game).to receive(:puts).with("#{opponent_player.name}, do you accept the proposal of draw?")
            game.player_action
          end
        end

        context 'when the opponent accepts the draw' do
          10.times do
            it 'outputs a draw message' do
              expect(game).to receive(:puts).with('The game ends in a draw.')
              game.player_action
            end

            it 'ends the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).to be true
            end
          end
        end

        context 'when the opponent does not accept the draw' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[draw DRAW 3].sample, ['n', 'N', 'no', 'NO', 'yesterday', ''].sample)
          end

          10.times do
            it 'does not output a draw message' do
              expect(game).not_to receive(:puts).with('The game ends in a draw.')
              game.player_action
            end

            it 'does not end the game' do
              game.player_action
              game_over = game.instance_variable_get(:@game_over)
              expect(game_over).not_to be true
            end
          end
        end
      end

      context 'when the word "main" or "7" is entered' do
        10.times do
          it 'ends the current game' do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[main MAIN 7].sample)
            game.player_action
            game_over = game.instance_variable_get(:@game_over)
            expect(game_over).to be true
          end
        end
      end

      context 'while an invalid input is entered' do
        10.times do
          it 'prompts the user to enter an input until a valid input is entered' do
            invalid_count = rand(100)
            call_count = 0
            invalid_inputs = ["I don't know", 'menu', '20', 'b', '[0, 1]', ':help', '(']
            allow(game).to receive(:gets) do
              call_count += 1
              if call_count == 1
                %w[menu MENU].sample
              elsif call_count == invalid_count + 2
                %w[back BACK 8].sample
              else invalid_inputs.sample
              end
            end
            expect(game).to receive(:puts).with('Invalid input!').exactly(invalid_count).times
            game.player_action
          end
        end
      end
    end
  end
end
