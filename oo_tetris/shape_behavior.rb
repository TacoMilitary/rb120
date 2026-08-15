require_relative 'grid_behavior'

module TetrisShapes
  ROTATE_CENTER = :rotate_center
  LIMB_DATA = :limb_data

  FILLED_CELL_PATTERN = 'N'
  EMPTY_CELL_PATTERN = ' '

  # Golomb names taken from
  # "https://quuxplusone.github.io/blog/2025/04/19/tetromino-names/"
  #
  # :rotate_center is the coordinates of the
  # limb that the shape rotates around. if this is not provided
  # it is assumed that the shape cannot rotate

  SHAPES =
    [
      # Square tetromino
      { LIMB_DATA => "NN\nNN" },

      # T-tetromino
      { LIMB_DATA => " N\nNNN", ROTATE_CENTER => { y: 1, x: 1 } },

      # Straight tetromino
      { LIMB_DATA => "NNNN", ROTATE_CENTER => { y: 0, x: 0 } },

      # Skrew tetromino green
      { LIMB_DATA => " NN\nNN", ROTATE_CENTER => { y: 1, x: 1 } },

      # Skrew tetromino red
      { LIMB_DATA => "NN\n NN", ROTATE_CENTER => { y: 1, x: 1 } },

      # L-tetromino blue
      { LIMB_DATA => "N\nNNN", ROTATE_CENTER => { y: 1, x: 0 } },

      # L-tetromino orange
      { LIMB_DATA => "  N\nNNN", ROTATE_CENTER => { y: 1, x: 2 } }
    ].freeze

  def self.random_shape
    Shape.new(SHAPES.sample)
  end
end

class Shape
  FILLED_CELL_PATTERN = TetrisShapes::FILLED_CELL_PATTERN
  EMPTY_CELL_PATTERN = TetrisShapes::EMPTY_CELL_PATTERN
  EMPTY_SPACE_VISUAL = ' ' * Cell::FILLED_CELL_VISUAL.size

  CLOCKWISE_SIGN = 1
  COUNTER_CLOCKWISE_SIGN = -1

  VISUAL_REGEX = /#{FILLED_CELL_PATTERN}|#{EMPTY_CELL_PATTERN}/
  VISUAL_HASH = {
    FILLED_CELL_PATTERN => Cell::FILLED_CELL_VISUAL,
    EMPTY_CELL_PATTERN => EMPTY_SPACE_VISUAL
  }

  DEFAULT_POSITION = { y: 1, x: 1 }

  attr_reader :visual, :limbs, :center_limb
  attr_accessor :position

  def initialize(shape_data)
    limb_data = shape_data[TetrisShapes::LIMB_DATA]

    @visual = create_visual(limb_data)
    @limbs = translate_string_to_limbs(limb_data)
    @position = DEFAULT_POSITION.dup
    @center_limb = find_center_limb shape_data[TetrisShapes::ROTATE_CENTER]
  end

  def filled_coords
    limbs.map { |limb| limb_absolute_coord(limb) }
  end

  def filled_x_coords
    filled_coords.each_with_object(Set.new) { |coord, set| set << coord[:x] }
  end

  def rotate(rotation_direction = CLOCKWISE_SIGN)
    return unless can_rotate?

    offset_position_by_rotation
    limbs.each { |limb| rotate_limb!(limb, rotation_direction) }
  end

  def absolute_center_coord
    return nil unless can_rotate?

    limb_absolute_coord(center_limb)
  end

  alias to_s visual

  private

  def can_rotate?
    !!center_limb
  end

  def offset_position_by_rotation
    rotated_center = limb_rotated(center_limb, rotation_direction)

    position[:x] -= rotated_center[:x] - center_limb[:x]
    position[:y] -= rotated_center[:y] - center_limb[:y]
  end

  def rotate_limb!(limb, rotation_direction = CLOCKWISE_SIGN)
    rotated_coord = limb_rotated(limb, rotation_direction)
    limb.merge!(rotated_coord)
  end

  def limb_rotated(limb, rotation_direction = CLOCKWISE_SIGN)
    { y: limb[:x] * -rotation_direction, x: limb[:y] * rotation_direction }
  end

  def limb_absolute_coord(limb)
    {
      y: position[:y] + limb[:y],
      x: position[:x] + limb[:x]
    }
  end

  def create_visual(shape_string)
    shape_string.gsub(VISUAL_REGEX, VISUAL_HASH)
  end

  def find_center_limb(rotation_limb)
    limbs.find { |limb| limb == rotation_limb }
  end

  def translate_string_to_limbs(shape_string)
    data = []
    shape_string.split(/$/).each_with_index do |row, y_coord|
      clean_row = row.delete "\n"
      data.concat row_shape_x_coords(y_coord, clean_row)
    end

    data
  end

  # rubocop:disable Metrics/MethodLength
  def row_shape_x_coords(y_coord, row_shape_string)
    current_coord = 0
    last_matched_index = 0
    row_coords = []
    (0...row_shape_string.size).each do |substr_index|
      pattern = row_shape_string[last_matched_index..substr_index]
      if [EMPTY_CELL_PATTERN, FILLED_CELL_PATTERN].include? pattern
        row_coords << { y: y_coord, x: current_coord } if cell_pattern?(pattern)
        current_coord += 1
        last_matched_index = substr_index.next
      end
    end
    row_coords
  end
  # rubocop:enable Metrics/MethodLength

  def cell_pattern?(pattern)
    pattern == FILLED_CELL_PATTERN
  end
end
