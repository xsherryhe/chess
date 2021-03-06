# frozen_string_literal: true

require 'yaml'
Dir[__dir__ + '/*.rb'].sort.each do |file|
  require file unless file.include?('piece')
end
require_relative '.././chess_base.rb'

class Piece
  include BaseMethods

  attr_accessor :position
  attr_reader :player_index, :symbol, :illegal_check_next_positions

  def initialize(player_index, starting_position)
    @player_index = player_index
    @position = starting_position
  end

  def move(goal_pos, *)
    @position = goal_pos
  end

  def legal_next_positions(board, move_num)
    king = player_king(board)
    @illegal_check_next_positions, legal_next_positions =
      next_positions(board, move_num).partition do |next_pos|
        king_in_check?(king, next_pos, board, move_num)
      end
    legal_next_positions
  end

  def next_positions(board, *)
    base_positions.each_slice(7).map do |pos_set|
      pos_set = in_range(pos_set)
      last_index = pos_set.index do |pos|
        board.any? { |piece| piece.position == pos }
      end
      pos_set[0..(last_index || -1)].reject do |pos|
        board.any? { |piece| player?(piece) && piece.position == pos }
      end
    end.flatten(1)
  end

  def to_yaml
    YAML.dump(serialize_vals)
  end

  def self.from_yaml(string)
    piece_class, data = YAML.safe_load(string).values
    piece = Module.const_get(piece_class).new(data['player_index'],
                                              data['position'])
    data.each do |key, val|
      var = ('@' + key).to_sym
      piece.instance_variable_set(var, val)
    end
    piece
  end

  private

  def serialize_vals
    { 'class' => self.class.name,
      'data' => { 'player_index' => @player_index, 'position' => @position } }
  end

  def king_in_check?(king, next_pos, board, move_num)
    moved_piece = clone
    moved_piece.position = next_pos
    moved_board = board - [self] + [moved_piece]
    capture_piece(index_to_capture(moved_piece, moved_board), moved_board)
    king.checked?((moved_piece.is_a?(King) ? moved_piece : king).position,
                  moved_board, move_num)
  end

  def base_positions
    @base_moves.map do |move|
      [position.first + move.first, position.last + move.last]
    end
  end

  def in_range(positions)
    positions.select do |pos|
      pos.all? { |dir| dir.between?(0, 7) }
    end
  end
end
