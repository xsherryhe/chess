require_relative '../lib/chess_game.rb'

describe Game do
  subject(:game) { described_class.new }
  let(:white_player) { instance_double(Player, name: 'Foo', player_index: 0, color: 'White') }
  let(:black_player) { instance_double(Player, name: 'Bar', player_index: 1, color: 'Black') }
  let(:players) { game.instance_variable_get(:@players) }
  let(:board) { game.instance_variable_get(:@board) }

  before do
    allow(Player).to receive(:new).and_return(white_player, black_player)
    allow(game).to receive(:puts)
  end

  describe '#player_action' do
    context 'when the word "menu" is entered' do
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
        allow(game).to receive(:save_dir).and_return(mock_save_dir)
        allow(game).to receive(:save_record).and_return(mock_save_record)
      end

      context 'when the word "save" or "4" is entered' do
        let(:legal_save_name) { %w[save1 SAVE1 123 test].sample }

        before do
          allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[save SAVE 4].sample, legal_save_name, %w[y Y yes YES].sample)
          allow(Dir).to receive(:mkdir)
          clear_save_record
          clear_save_dir
        end

        after do
          clear_save_record
          clear_save_dir
        end

        context 'when the save directory and record have not been created' do
          before do
            allow(Dir).to receive(:exist?).with(mock_save_dir).and_return(false)
            allow(File).to receive(:exist?).with(mock_save_record).and_return(false)
            allow(File).to receive(:write)
          end

          it 'creates a save directory and record' do
            expect(Dir).to receive(:mkdir).with(mock_save_dir)
            expect(File).to receive(:write).with(mock_save_record, '')
            game.player_action
          end
        end

        context 'when the save directory and record already exist' do
          before do
            allow(Dir).to receive(:exist?).with(mock_save_dir).and_return(true)
            allow(File).to receive(:exist?).with(mock_save_record).and_return(true)
            allow(File).to receive(:write)
          end

          it 'does not create a save directory and record' do
            expect(Dir).not_to receive(:mkdir).with(mock_save_dir)
            expect(File).not_to receive(:write).with(mock_save_record, '')
            game.player_action
          end
        end

        context 'when the save directory has fewer than 20 saved files' do
          it 'prompts the user to enter a new save name' do
            expect(game).to receive(:puts).with(/Please type a name for your save file/)
            game.player_action
          end

          context 'when a legal save name is entered' do
            10.times do
              it 'adds the save name to the save record' do
                game.player_action
                save_record = File.read(mock_save_record)
                expect(save_record).to include(legal_save_name.downcase)
              end

              it 'creates a yaml file with the serialized game' do
                game.player_action
                file_exist = File.exist?("#{mock_save_dir}/#{legal_save_name.downcase}.yaml")
                expect(file_exist).to be true
              end

              it 'outputs a save success message' do
                expect(game).to receive(:puts).with("Game \"#{legal_save_name.downcase}\" successfully saved!")
                game.player_action
              end

              it 'offers the user to exit the game' do
                expect(game).to receive(:puts).with('Exit to main menu? Y/N')
                game.player_action
              end
            end
          end

          context 'when the words "go back" are entered' do
            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[save SAVE 4].sample, ['go back', 'GO BACK'].sample, %w[back BACK 8].sample)
            end

            it 'does not add anything to the save record' do
              game.player_action
              save_record = File.read(mock_save_record)
              expect(save_record).to eq(' ')
            end

            it 'does not create a yaml file with the serialized game' do
              game.player_action
              dir_empty = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.empty?
              expect(dir_empty).to be true
            end

            it 'does not output a save success message' do
              expect(game).not_to receive(:puts).with(/successfully saved/)
              game.player_action
            end

            it 'does not offer the user to exit the game' do
              expect(game).not_to receive(:puts).with('Exit to main menu? Y/N')
              game.player_action
            end
          end

          context 'while an invalid input is entered' do
            let(:invalid_count) { rand(100) }
            before do
              call_count = 0
              allow(game).to receive(:gets) do
                call_count += 1
                case call_count
                when 1 then %w[menu MENU].sample
                when 2 then %w[save SAVE 4].sample
                when invalid_count + 3 then legal_save_name
                else invalid_inputs.sample
                end
              end
            end

            context 'while a save name that is too short or long is entered' do
              let(:invalid_inputs) { ['0' * 20, ''] }
              10.times do
                it 'prompts the user to enter a save name that fits length requirements until it is entered' do
                  expect(game).to receive(:puts).with("Error!\r\nPlease enter a string between 1 and 15 characters.").exactly(invalid_count).times
                  game.player_action
                end
              end
            end

            context 'while a save name that contains non-letter/non-number characters is entered' do
              let(:invalid_inputs) { [' ', '@saving', '(', '\\', 'test-123', 'my save!'] }
              10.times do
                it 'prompts the user to enter a letter/number-only save name until it is entered' do
                  expect(game).to receive(:puts).with("Error!\r\nPlease enter a string using letters/numbers only.").exactly(invalid_count).times
                  game.player_action
                end
              end
            end

            context 'while a save name that includes both errors is entered' do
              let(:invalid_inputs) { [' ' * 30, '@saving' * 10, '(' * 20, 'test-123' * 15, 'my save!' * 12] }
              10.times do
                it 'prompts the user with both error messages until a legal save name is entered' do
                  expect(game)
                    .to receive(:puts)
                    .with("Error!\r\nPlease enter a string between 1 and 15 characters.\r\nPlease enter a string using letters/numbers only.")
                    .exactly(invalid_count).times
                  game.player_action
                end
              end
            end
          end
        end

        context 'when the save directory is full (i.e. has 20 saved files)' do
          let(:existing_save_name) { rand(20).to_s + %w[a A].sample }

          before do
            File.open(mock_save_record, 'w') do |record_file|
              20.times { |i| record_file.puts("#{i}a") }
            end
            20.times { |i| File.write("#{mock_save_dir}/#{i}a.yaml", '') }
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample,
                                                     %w[save SAVE 4].sample,
                                                     existing_save_name,
                                                     %w[y Y yes YES].sample,
                                                     %w[y Y yes YES].sample)
          end

          it 'outputs a save folder full message' do
            expect(game).to receive(:puts).with('Your save folder is full.')
            game.player_action
          end

          it 'prompts the user to enter an existing save name to overwrite' do
            expect(game).to receive(:puts).with(/Please type the name of an existing save file to overwrite/)
            game.player_action
          end

          context 'when an existing save name is entered' do
            10.times do
              it 'prompts the user to confirm overwrite of the save' do
                expect(game).to receive(:puts).with("Overwrite the save file named \"#{existing_save_name.downcase}\"? Y/N")
                game.player_action
              end
            end

            context 'when the save overwrite is confirmed' do
              10.times do
                it 'updates the corresponding yaml file with the serialized game' do
                  game.player_action
                  file = File.read("#{mock_save_dir}/#{existing_save_name.downcase}.yaml")
                  expect(file).not_to eq('')
                end

                it 'outputs a save success message' do
                  expect(game).to receive(:puts).with("Game \"#{existing_save_name.downcase}\" successfully saved!")
                  game.player_action
                end

                it 'offers the user to exit the game' do
                  expect(game).to receive(:puts).with('Exit to main menu? Y/N')
                  game.player_action
                end
              end
            end

            context 'while the save overwrite is not confirmed' do
              10.times do
                it 'prompts the user to enter an existing save name until an existing save name is entered and confirmed' do
                  no_confirm_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[save SAVE 4].sample
                    elsif call_count.odd? then existing_save_name
                    elsif call_count == no_confirm_count * 2 + 4 then %w[y Y yes YES].sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end
                  expect(game).to receive(:puts).with(/Please type the name of an existing save file to overwrite/).exactly(no_confirm_count + 1).times
                  game.player_action
                end
              end
            end
          end

          context 'when the words "go back" are entered' do
            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[save SAVE 4].sample, ['go back', 'GO BACK'].sample, %w[back BACK 8].sample)
            end

            10.times do
              it 'does not update a yaml file with the serialized game' do
                game.player_action
                files = 20.times.map { |i| File.read("#{mock_save_dir}/#{i}a.yaml") }
                expect(files).to all(eq(''))
              end

              it 'does not output a save success message' do
                expect(game).not_to receive(:puts).with(/successfully saved/)
                game.player_action
              end

              it 'does not offer the user to exit the game' do
                expect(game).not_to receive(:puts).with('Exit to main menu? Y/N')
                game.player_action
              end
            end
          end

          context 'when an invalid input (i.e., non-existing save name) is entered' do
            let(:non_existing_save_names) { ['save1', 'SAVE1', '123', 'test', '0' * 15, '', ' ', '@saving', '(', '\\', 'test-123', 'my save!'] }

            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample,
                                                       %w[save SAVE 4].sample,
                                                       non_existing_save_names.sample,
                                                       ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample,
                                                       %w[back BACK 8].sample)
            end

            10.times do
              it 'prompts the user to confirm cancellation of a save overwrite' do
                expect(game).to receive(:puts).with('There is no save file with this name. Resume game without saving? Y/N')
                game.player_action
              end
            end

            context 'when cancellation of the save overwrite is confirmed' do
              10.times do
                it 'does not update a yaml file with the serialized game' do
                  game.player_action
                  files = 20.times.map { |i| File.read("#{mock_save_dir}/#{i}a.yaml") }
                  expect(files).to all(eq(''))
                end

                it 'does not output a save success message' do
                  expect(game).not_to receive(:puts).with(/successfully saved/)
                  game.player_action
                end

                it 'does not offer the user to exit the game' do
                  expect(game).not_to receive(:puts).with('Exit to main menu? Y/N')
                  game.player_action
                end
              end
            end

            context 'while cancellation of the save overwrite is not confirmed' do
              10.times do
                it 'prompts the user to enter an existing save name until cancellation of the save overwrite is confirmed' do
                  no_cancel_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[save SAVE 4].sample
                    elsif call_count == no_cancel_count * 2 + 4 then ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample
                    elsif call_count == no_cancel_count * 2 + 5 then %w[back BACK 8].sample
                    elsif call_count.odd? then non_existing_save_names.sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end

                  expect(game).to receive(:puts).with(/Please type the name of an existing save file to overwrite/).exactly(no_cancel_count + 1).times
                  game.player_action
                end

                it 'prompts the user to enter an existing save name until an existing save name is entered and confirmed' do
                  invalid_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[save SAVE 4].sample
                    elsif call_count == invalid_count * 2 + 3 then existing_save_name
                    elsif call_count >= invalid_count * 2 + 4 then %w[y Y yes YES].sample
                    elsif call_count.odd? then non_existing_save_names.sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end

                  expect(game).to receive(:puts).with(/Please type the name of an existing save file to overwrite/).exactly(invalid_count + 1).times
                  game.player_action
                end
              end
            end
          end
        end
      end

      context 'when the word "load" or "5" is entered' do
        before do
          clear_save_record
          clear_save_dir
          allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[load LOAD 5].sample, existing_save_name, '')
        end

        after do
          clear_save_record
          clear_save_dir
        end

        context 'when previous save files exist' do
          let(:saved_game_board) do
            Array.new(rand(32)) do
              [King, Queen, Rook, Bishop, Knight, Pawn].sample.new(rand(2), Array.new(2) { rand(8) })
            end
          end
          let(:saved_game_players) do
            players = [instance_double(Player, name: rand(100).to_s, player_index: 0),
                       instance_double(Player, name: rand(100).to_s, player_index: 1)]
            players.each do |player|
              allow(player).to receive(:to_yaml).and_return(YAML.dump('player_index' => player.player_index, 'name' => player.name))
            end
            players
          end

          before do
            File.open(mock_save_record, 'w') do |record_file|
              20.times { |i| record_file.puts("#{i}a") }
            end
            20.times { |i| File.write("#{mock_save_dir}/#{i}a.yaml", '') }
            saved_game = described_class.new
            saved_game.instance_variable_set(:@board, saved_game_board)
            saved_game.instance_variable_set(:@players, saved_game_players)
            File.write("#{mock_save_dir}/#{existing_save_name.downcase}.yaml", saved_game.to_yaml)
            allow(Player).to receive(:from_yaml) do |string|
              data = YAML.safe_load(string)
              instance_double(Player, name: data['name'], player_index: data['player_index'])
            end
          end

          it 'prompts the user to enter the name of an existing save file' do
            expect(game).to receive(:puts).with(/Please type the name of the game you wish to load/)
            game.player_action
          end

          context 'when an existing save name is entered' do
            10.times do
              it 'updates the game with data from the corresponding file' do
                def instance_vals(piece)
                  piece.instance_variables.map { |var| piece.instance_variable_get(var) }
                end

                game.player_action
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

              it 'outputs a load success message' do
                expect(game).to receive(:puts).with("Game \"#{existing_save_name.downcase}\" successfully loaded!")
                game.player_action
              end
            end
          end

          context 'when the words "go back" are entered' do
            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[load LOAD 5].sample, ['go back', 'GO BACK'].sample, %w[back BACK 8].sample)
            end

            10.times do
              it 'does not update the game with data from the corresponding file' do
                starting_board = game.instance_variable_get(:@board)
                starting_players = game.instance_variable_get(:@players)
                game.player_action
                expect(board).to eq(starting_board)
                expect(players).to eq(starting_players)
              end

              it 'does not output a load success message' do
                expect(game).not_to receive(:puts).with(/successfully loaded/)
                game.player_action
              end
            end
          end

          context 'when an invalid input (i.e., non-existing save name) is entered' do
            let(:non_existing_save_names) { ['save1', 'SAVE1', '123', 'test', '0' * 15, '', ' ', '@saving', '(', '\\', 'test-123', 'my save!'] }

            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample,
                                                       %w[load LOAD 5].sample,
                                                       non_existing_save_names.sample,
                                                       ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample,
                                                       %w[back BACK 8].sample)
            end

            10.times do
              it 'prompts the user to return to the menu' do
                expect(game).to receive(:puts).with('There is no save file with this name. Return to the menu? Y/N')
                game.player_action
              end
            end

            context 'when returning to the menu is confirmed' do
              10.times do
                it 'does not update the game with data from the corresponding file' do
                  starting_board = game.instance_variable_get(:@board)
                  starting_players = game.instance_variable_get(:@players)
                  game.player_action
                  expect(board).to eq(starting_board)
                  expect(players).to eq(starting_players)
                end

                it 'does not output a load success message' do
                  expect(game).not_to receive(:puts).with(/successfully loaded/)
                  game.player_action
                end
              end
            end

            context 'while returning to the menu is not confirmed' do
              10.times do
                it 'prompts the user to enter an existing save name until returning to the menu is confirmed' do
                  no_menu_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[load LOAD 5].sample
                    elsif call_count == no_menu_count * 2 + 4 then ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample
                    elsif call_count == no_menu_count * 2 + 5 then %w[back BACK 8].sample
                    elsif call_count.odd? then non_existing_save_names.sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end

                  expect(game).to receive(:puts).with(/Please type the name of the game you wish to load/).exactly(no_menu_count + 1).times
                  game.player_action
                end

                it 'prompts the user to enter an existing save name until an existing save name is entered' do
                  invalid_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[load LOAD 5].sample
                    elsif call_count == invalid_count * 2 + 3 then existing_save_name
                    elsif call_count == invalid_count * 2 + 4 then ''
                    elsif call_count.odd? then non_existing_save_names.sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end

                  expect(game).to receive(:puts).with(/Please type the name of the game you wish to load/).exactly(invalid_count + 1).times
                  game.player_action
                end
              end
            end
          end
        end

        context 'when previous save files do not exist' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[load LOAD 5].sample, %w[back BACK 8].sample)
          end

          it 'outputs a no save files message' do
            expect(game).to receive(:puts).with('You have no saved games.')
            game.player_action
          end

          it 'does not update the game with data from the corresponding file' do
            starting_board = game.instance_variable_get(:@board)
            starting_players = game.instance_variable_get(:@players)
            game.player_action
            expect(board).to eq(starting_board)
            expect(players).to eq(starting_players)
          end

          it 'does not output a load success message' do
            expect(game).not_to receive(:puts).with(/successfully loaded/)
            game.player_action
          end
        end
      end

      context 'when the word "delete" or "6" is entered' do
        before do
          clear_save_record
          clear_save_dir
          allow(game).to receive(:gets).and_return(%w[menu MENU].sample,
                                                   %w[delete DELETE 6].sample,
                                                   existing_save_name,
                                                   ['n', 'N', 'no', 'NO', 'yesterday', ''].sample,
                                                   '', %w[back BACK 8].sample)
        end

        after do
          clear_save_record
          clear_save_dir
        end

        context 'when previous save files exist' do
          before do
            File.open(mock_save_record, 'w') do |record_file|
              20.times { |i| record_file.puts("#{i}a") }
            end
            20.times { |i| File.write("#{mock_save_dir}/#{i}a.yaml", '') }
          end

          it 'prompts the user to enter the name of an existing save file' do
            expect(game).to receive(:puts).with(/Please type the name of the game you wish to delete/)
            game.player_action
          end

          context 'when an existing save name is entered' do
            10.times do
              it 'deletes the corresponding file' do
                game.player_action
                saved_files = Dir.glob("#{mock_save_dir}/*.yaml")
                expect(saved_files).not_to include("#{mock_save_dir}/#{existing_save_name.downcase}.yaml")
              end

              it 'deletes the save name from the save record' do
                game.player_action
                saved_names = File.readlines(mock_save_record)
                expect(saved_names).not_to include(existing_save_name.downcase + "\n")
              end

              it 'outputs a load success message' do
                expect(game).to receive(:puts).with("Game \"#{existing_save_name.downcase}\" successfully deleted!")
                game.player_action
              end
            end

            context 'when additional save files exist' do
              it 'prompts the user to delete another game' do
                expect(game).to receive(:puts).with('Would you like to delete another game? Y/N')
                game.player_action
              end

              context 'when deleting additional save files is not confirmed' do
                10.times do
                  it 'outputs a return to menu message' do
                    expect(game).to receive(:puts).with('Press ENTER to return to the menu.')
                    game.player_action
                  end
                end
              end

              context 'while deleting additional save files is confirmed' do
                let(:extra_delete_count) { rand(20) }
                let(:all_existing_save_names) do
                  (0...20).to_a.product(%w[A a]).map(&:join)
                end
                let(:deleted_save_names) { [] }

                before do
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[delete DELETE 6].sample
                    elsif call_count == extra_delete_count * 2 + 4 then ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    elsif call_count == extra_delete_count * 2 + 5 then ''
                    elsif call_count == extra_delete_count * 2 + 6 then %w[back BACK 8].sample
                    elsif call_count.odd?
                      save_name = all_existing_save_names.sample
                      all_existing_save_names.reject! { |name| name.downcase == save_name.downcase }
                      deleted_save_names << save_name
                      save_name
                    else %w[y Y yes YES].sample
                    end
                  end
                end

                10.times do
                  it 'prompts the user to enter the name of additional existing save files until deleting additional save files is no longer confirmed' do
                    expect(game).to receive(:puts).with(/Please type the name of the game you wish to delete/).exactly(extra_delete_count + 1).times
                    game.player_action
                  end

                  it 'deletes all corresponding save files' do
                    game.player_action
                    saved_files = Dir.glob("#{mock_save_dir}/*.yaml")
                    deleted_files = deleted_save_names.map { |name| "#{mock_save_dir}/#{name.downcase}.yaml" }
                    expect(saved_files).not_to include(*deleted_files)
                  end

                  it 'deletes all corresponding save names from the save record' do
                    game.player_action
                    saved_names = File.readlines(mock_save_record)
                    deleted_names = deleted_save_names.map { |name| name.downcase + "\n" }
                    expect(saved_names).not_to include(*deleted_names)
                  end

                  it 'outputs a load success message for each deleted save file' do
                    expect(game).to receive(:puts).with(/successfully deleted/).exactly(extra_delete_count + 1).times
                    game.player_action
                  end
                end
              end
            end

            context 'when no additional save files exist' do
              before do
                File.open(mock_save_record, 'w') { |record_file| record_file.puts(existing_save_name.downcase) }
                clear_save_dir
                File.write("#{mock_save_dir}/#{existing_save_name.downcase}.yaml", '')
              end

              it 'does not prompt the user to delete another game' do
                expect(game).not_to receive(:puts).with('Would you like to delete another game? Y/N')
                game.player_action
              end
            end
          end

          context 'when the words "go back" are entered' do
            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[delete DELETE 6].sample, ['go back', 'GO BACK'].sample, %w[back BACK 8].sample)
            end

            10.times do
              it 'does not delete any save files' do
                game.player_action
                saved_file_num = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.size
                expect(saved_file_num).to eq(20)
              end

              it 'does not delete any save names from the save record' do
                game.player_action
                saved_name_num = File.readlines(mock_save_record).size
                expect(saved_name_num).to eq(20)
              end

              it 'does not output a load success message' do
                expect(game).not_to receive(:puts).with(/successfully deleted/)
                game.player_action
              end
            end
          end

          context 'when an invalid input (i.e., non-existing save name) is entered' do
            let(:non_existing_save_names) { ['save1', 'SAVE1', '123', 'test', '0' * 15, '', ' ', '@saving', '(', '\\', 'test-123', 'my save!'] }

            before do
              allow(game).to receive(:gets).and_return(%w[menu MENU].sample,
                                                       %w[delete DELETE 6].sample,
                                                       non_existing_save_names.sample,
                                                       ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample,
                                                       %w[back BACK 8].sample)
            end

            10.times do
              it 'prompts the user to return to the menu' do
                expect(game).to receive(:puts).with('There is no save file with this name. Return to the menu? Y/N')
                game.player_action
              end
            end

            context 'when returning to the menu is confirmed' do
              10.times do
                it 'does not delete any save files' do
                  game.player_action
                  saved_file_num = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.size
                  expect(saved_file_num).to eq(20)
                end

                it 'does not delete any save names from the save record' do
                  game.player_action
                  saved_name_num = File.readlines(mock_save_record).size
                  expect(saved_name_num).to eq(20)
                end

                it 'does not output a load success message' do
                  expect(game).not_to receive(:puts).with(/successfully deleted/)
                  game.player_action
                end
              end
            end

            context 'while returning to the menu is not confirmed' do
              10.times do
                it 'prompts the user to enter an existing save name until returning to the menu is confirmed' do
                  no_menu_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[delete DELETE 6].sample
                    elsif call_count == no_menu_count * 2 + 5 then %w[back BACK 8].sample
                    elsif call_count.odd? then non_existing_save_names.sample
                    elsif call_count == no_menu_count * 2 + 4 then ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end

                  expect(game).to receive(:puts).with(/Please type the name of the game you wish to delete/).exactly(no_menu_count + 1).times
                  game.player_action
                end

                it 'prompts the user to enter an existing save name until an existing save name is entered' do
                  invalid_count = rand(100)
                  call_count = 0
                  allow(game).to receive(:gets) do
                    call_count += 1
                    if call_count == 1 then %w[menu MENU].sample
                    elsif call_count == 2 then %w[delete DELETE 6].sample
                    elsif call_count == invalid_count * 2 + 3 then existing_save_name
                    elsif call_count == invalid_count * 2 + 5 then ''
                    elsif call_count == invalid_count * 2 + 6 then %w[back BACK 8].sample
                    elsif call_count.odd? then non_existing_save_names.sample
                    else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                    end
                  end

                  expect(game).to receive(:puts).with(/Please type the name of the game you wish to delete/).exactly(invalid_count + 1).times
                  game.player_action
                end
              end
            end
          end
        end

        context 'when previous save files do not exist' do
          before do
            allow(game).to receive(:gets).and_return(%w[menu MENU].sample, %w[delete DELETE 6].sample, %w[back BACK 8].sample)
          end

          it 'does not change the save directory' do
            game.player_action
            saved_file_num = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.size
            expect(saved_file_num).to eq(0)
          end

          it 'does not change the save record' do
            game.player_action
            save_record = File.read(mock_save_record)
            expect(save_record).to eq(' ')
          end

          it 'does not output a load success message' do
            expect(game).not_to receive(:puts).with(/successfully deleted/)
            game.player_action
          end
        end
      end
    end
  end
end
