require_relative '../lib/chess.rb'

describe Chess do
  describe '::run' do
    let(:mock_save_dir) { "#{__dir__}/mock_saves" }
    let(:mock_save_record) { "#{__dir__}/mock_saves/mock_save_record.txt" }
    let(:existing_save_name) { rand(20).to_s + %w[a A].sample }
    let(:game) { instance_double(Game) }

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
      allow(Chess).to receive(:save_dir).and_return(mock_save_dir)
      allow(Chess).to receive(:save_record).and_return(mock_save_record)
      allow(Chess).to receive(:puts)
      allow(game).to receive(:play)
    end

    10.times do
      it 'outputs a list of game menu options until the menu is closed' do
        loop_count = rand(1..100)
        call_count = 0
        allow(Chess).to receive(:select_menu_option) do
          call_count += 1
          if call_count == loop_count
            Chess.instance_variable_set(:@menu_done, true)
          end
        end
        expect(Chess).to receive(:puts).with(/Enter one of the following commands:/).exactly(loop_count).times
        Chess.run
      end
    end

    context 'when the word "exit" or "5" is entered' do
      10.times do
        it 'exits the method' do
          allow(Chess).to receive(:gets).and_return(%w[exit EXIT 5].sample)
          Chess.run
        end
      end
    end

    context 'when the word "new" or "1" is entered' do
      before do
        allow(Chess).to receive(:gets).and_return(%w[new NEW 1].sample, %w[exit EXIT 5].sample)
        allow(Game).to receive(:new).and_return(game)
      end

      10.times do
        it 'creates a new game' do
          expect(Game).to receive(:new)
          Chess.run
        end

        it 'starts playing the new game' do
          expect(game).to receive(:play)
          Chess.run
        end
      end
    end

    context 'when the word "load" or "2" is entered' do
      before do
        clear_save_record
        clear_save_dir
        allow(Game).to receive(:from_yaml).and_return(game)
        allow(Chess).to receive(:gets).and_return(%w[load LOAD 2].sample, existing_save_name, '', %w[exit EXIT 5].sample)
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
          expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to load/)
          Chess.run
        end

        context 'when an existing save name is entered' do
          10.times do
            it 'creates a game from the corresponding save name file' do
              expect(Game).to receive(:from_yaml)
              Chess.run
            end

            it 'starts playing the loaded game' do
              expect(game).to receive(:play)
              Chess.run
            end

            it 'outputs a load success message' do
              expect(Chess).to receive(:puts).with("Game \"#{existing_save_name.downcase}\" successfully loaded!")
              Chess.run
            end
          end
        end

        context 'when the words "go back" are entered' do
          before do
            allow(Chess).to receive(:gets).and_return(%w[load LOAD 2].sample, ['go back', 'GO BACK'].sample, %w[exit EXIT 5].sample)
          end

          10.times do
            it 'does not create a game from any file' do
              expect(Game).not_to receive(:from_yaml)
              Chess.run
            end

            it 'does not output a load success message' do
              expect(Chess).not_to receive(:puts).with(/successfully loaded/)
              Chess.run
            end
          end
        end

        context 'when an invalid input (i.e., non-existing save name) is entered' do
          let(:non_existing_save_names) { ['save1', 'SAVE1', '123', 'test', '0' * 15, '', ' ', '@saving', '(', '\\', 'test-123', 'my save!'] }

          before do
            allow(Chess).to receive(:gets).and_return(%w[load LOAD 2].sample,
                                                      non_existing_save_names.sample,
                                                      ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample,
                                                      %w[exit EXIT 5].sample)
          end

          10.times do
            it 'prompts the user to return to the menu' do
              expect(Chess).to receive(:puts).with('There is no save file with this name. Return to the menu? Y/N')
              Chess.run
            end
          end

          context 'when returning to the menu is confirmed' do
            10.times do
              it 'does not create a game from any file' do
                expect(Game).not_to receive(:from_yaml)
                Chess.run
              end

              it 'does not output a load success message' do
                expect(Chess).not_to receive(:puts).with(/successfully loaded/)
                Chess.run
              end
            end
          end

          context 'while returning to the menu is not confirmed' do
            10.times do
              it 'prompts the user to enter an existing save name until returning to the menu is confirmed' do
                no_menu_count = rand(100)
                call_count = 0
                allow(Chess).to receive(:gets) do
                  call_count += 1
                  if call_count == 1 then %w[load LOAD 2].sample
                  elsif call_count == no_menu_count * 2 + 3 then ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample
                  elsif call_count == no_menu_count * 2 + 4 then %w[exit EXIT 5].sample
                  elsif call_count.even? then non_existing_save_names.sample
                  else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                  end
                end

                expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to load/).exactly(no_menu_count + 1).times
                Chess.run
              end

              it 'prompts the user to enter an existing save name until an existing save name is entered' do
                invalid_count = rand(100)
                call_count = 0
                allow(Chess).to receive(:gets) do
                  call_count += 1
                  if call_count == 1 then %w[load LOAD 2].sample
                  elsif call_count == invalid_count * 2 + 2 then existing_save_name
                  elsif call_count == invalid_count * 2 + 3 then ''
                  elsif call_count == invalid_count * 2 + 4 then %w[exit EXIT 5].sample
                  elsif call_count.even? then non_existing_save_names.sample
                  else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                  end
                end

                expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to load/).exactly(invalid_count + 1).times
                Chess.run
              end
            end
          end
        end
      end

      context 'when previous save files do not exist' do
        before do
          allow(Chess).to receive(:gets).and_return(%w[load LOAD 2].sample, %w[exit EXIT 5].sample)
        end

        it 'outputs a no save files message' do
          expect(Chess).to receive(:puts).with('You have no saved games.')
          Chess.run
        end

        it 'does not create a game from any file' do
          expect(Game).not_to receive(:from_yaml)
          Chess.run
        end

        it 'does not output a load success message' do
          expect(Chess).not_to receive(:puts).with(/successfully loaded/)
          Chess.run
        end
      end
    end

    context 'when the word "delete" or "3" is entered' do
      before do
        clear_save_record
        clear_save_dir
        allow(Chess).to receive(:gets).and_return(%w[delete DELETE 3].sample,
                                                  existing_save_name,
                                                  ['n', 'N', 'no', 'NO', 'yesterday', ''].sample,
                                                  '', %w[exit EXIT 5].sample)
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
          expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to delete/)
          Chess.run
        end

        context 'when an existing save name is entered' do
          10.times do
            it 'deletes the corresponding file' do
              Chess.run
              saved_files = Dir.glob("#{mock_save_dir}/*.yaml")
              expect(saved_files).not_to include("#{mock_save_dir}/#{existing_save_name.downcase}.yaml")
            end

            it 'deletes the save name from the save record' do
              Chess.run
              saved_names = File.readlines(mock_save_record)
              expect(saved_names).not_to include(existing_save_name.downcase + "\n")
            end

            it 'outputs a load success message' do
              expect(Chess).to receive(:puts).with("Game \"#{existing_save_name.downcase}\" successfully deleted!")
              Chess.run
            end
          end

          context 'when additional save files exist' do
            it 'prompts the user to delete another game' do
              expect(Chess).to receive(:puts).with('Would you like to delete another game? Y/N')
              Chess.run
            end

            context 'when deleting additional save files is not confirmed' do
              10.times do
                it 'outputs a return to menu message' do
                  expect(Chess).to receive(:puts).with('Press ENTER to return to the menu.')
                  Chess.run
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
                allow(Chess).to receive(:gets) do
                  call_count += 1
                  if call_count == 1 then %w[delete DELETE 3].sample
                  elsif call_count == extra_delete_count * 2 + 3 then ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                  elsif call_count == extra_delete_count * 2 + 4 then ''
                  elsif call_count == extra_delete_count * 2 + 5 then %w[exit EXIT 5].sample
                  elsif call_count.even?
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
                  expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to delete/).exactly(extra_delete_count + 1).times
                  Chess.run
                end

                it 'deletes all corresponding save files' do
                  Chess.run
                  saved_files = Dir.glob("#{mock_save_dir}/*.yaml")
                  deleted_files = deleted_save_names.map { |name| "#{mock_save_dir}/#{name.downcase}.yaml" }
                  expect(saved_files).not_to include(*deleted_files)
                end

                it 'deletes all corresponding save names from the save record' do
                  Chess.run
                  saved_names = File.readlines(mock_save_record)
                  deleted_names = deleted_save_names.map { |name| name.downcase + "\n" }
                  expect(saved_names).not_to include(*deleted_names)
                end

                it 'outputs a load success message for each deleted save file' do
                  expect(Chess).to receive(:puts).with(/successfully deleted/).exactly(extra_delete_count + 1).times
                  Chess.run
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
              expect(Chess).not_to receive(:puts).with('Would you like to delete another game? Y/N')
              Chess.run
            end
          end
        end

        context 'when the words "go back" are entered' do
          before do
            allow(Chess).to receive(:gets).and_return(%w[delete DELETE 3].sample, ['go back', 'GO BACK'].sample, %w[exit EXIT 5].sample)
          end

          10.times do
            it 'does not delete any save files' do
              Chess.run
              saved_file_num = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.size
              expect(saved_file_num).to eq(20)
            end

            it 'does not delete any save names from the save record' do
              Chess.run
              saved_name_num = File.readlines(mock_save_record).size
              expect(saved_name_num).to eq(20)
            end

            it 'does not output a load success message' do
              expect(Chess).not_to receive(:puts).with(/successfully deleted/)
              Chess.run
            end
          end
        end

        context 'when an invalid input (i.e., non-existing save name) is entered' do
          let(:non_existing_save_names) { ['save1', 'SAVE1', '123', 'test', '0' * 15, '', ' ', '@saving', '(', '\\', 'test-123', 'my save!'] }

          before do
            allow(Chess).to receive(:gets).and_return(%w[delete DELETE 3].sample,
                                                      non_existing_save_names.sample,
                                                      ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample,
                                                      %w[exit EXIT 5].sample)
          end

          10.times do
            it 'prompts the user to return to the menu' do
              expect(Chess).to receive(:puts).with('There is no save file with this name. Return to the menu? Y/N')
              Chess.run
            end
          end

          context 'when returning to the menu is confirmed' do
            10.times do
              it 'does not delete any save files' do
                Chess.run
                saved_file_num = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.size
                expect(saved_file_num).to eq(20)
              end

              it 'does not delete any save names from the save record' do
                Chess.run
                saved_name_num = File.readlines(mock_save_record).size
                expect(saved_name_num).to eq(20)
              end

              it 'does not output a load success message' do
                expect(Chess).not_to receive(:puts).with(/successfully deleted/)
                Chess.run
              end
            end
          end

          context 'while returning to the menu is not confirmed' do
            10.times do
              it 'prompts the user to enter an existing save name until returning to the menu is confirmed' do
                no_menu_count = rand(100)
                call_count = 0
                allow(Chess).to receive(:gets) do
                  call_count += 1
                  if call_count == 1 then %w[delete DELETE 3].sample
                  elsif call_count == no_menu_count * 2 + 3 then ['y', 'Y', 'yes', 'YES', 'go back', 'GO BACK'].sample
                  elsif call_count == no_menu_count * 2 + 4 then %w[exit EXIT 5].sample
                  elsif call_count.even? then non_existing_save_names.sample
                  else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                  end
                end

                expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to delete/).exactly(no_menu_count + 1).times
                Chess.run
              end

              it 'prompts the user to enter an existing save name until an existing save name is entered' do
                invalid_count = rand(100)
                call_count = 0
                allow(Chess).to receive(:gets) do
                  call_count += 1
                  if call_count == 1 then %w[delete DELETE 3].sample
                  elsif call_count == invalid_count * 2 + 2 then existing_save_name
                  elsif call_count == invalid_count * 2 + 4 then ''
                  elsif call_count == invalid_count * 2 + 5 then %w[exit EXIT 5].sample
                  elsif call_count.even? then non_existing_save_names.sample
                  else ['n', 'N', 'no', 'NO', 'yesterday', ''].sample
                  end
                end

                expect(Chess).to receive(:puts).with(/Please type the name of the game you wish to delete/).exactly(invalid_count + 1).times
                Chess.run
              end
            end
          end
        end
      end

      context 'when previous save files do not exist' do
        before do
          allow(Chess).to receive(:gets).and_return(%w[delete DELETE 3].sample, %w[exit EXIT 5].sample)
        end

        it 'does not change the save directory' do
          Chess.run
          saved_file_num = Dir.glob("#{mock_save_dir}/*.yaml").select { |file| File.file?(file) }.size
          expect(saved_file_num).to eq(0)
        end

        it 'does not change the save record' do
          Chess.run
          save_record = File.read(mock_save_record)
          expect(save_record).to eq(' ')
        end

        it 'does not output a load success message' do
          expect(Chess).not_to receive(:puts).with(/successfully deleted/)
          Chess.run
        end
      end
    end

    context 'while the word "help" or "4" is entered' do
      10.times do
        it 'outputs chess information the corresponding number of times' do
          help_count = rand(100)
          call_count = 0
          allow(Chess).to receive(:gets) do
            call_count += 1
            if call_count == (help_count * 2) + 1 then %w[exit EXIT 5].sample
            elsif call_count.odd? then %w[help HELP 4].sample
            else ''
            end
          end

          expect(Chess).to receive(:puts).with(/Chess is a board game with two players/).exactly(help_count).times
          Chess.run
        end
      end
    end

    context 'while an invalid input is entered' do
      10.times do
        it 'prompts the user to enter an input until a valid input is entered' do
          invalid_count = rand(100)
          call_count = 0
          invalid_inputs = ["I don't know", 'menu', '20', 'b', '[0, 1]', ':help', '(']
          allow(Chess).to receive(:gets) do
            call_count += 1
            call_count == invalid_count + 1 ?  %w[exit EXIT 5].sample : invalid_inputs.sample
          end
          expect(Chess).to receive(:puts).with('Invalid input!').exactly(invalid_count).times
          Chess.run
        end
      end
    end
  end
end
