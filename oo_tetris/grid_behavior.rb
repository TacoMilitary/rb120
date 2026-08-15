class Cell
  CELL_VISUAL_SIZE = 3
  EMPTY_CELL_VISUAL = '-'
  FILLED_CELL_VISUAL = '[ ]'
  CENTER_CELL_VISUAL = '[+]'
  SHADOW_CELL_VISUAL = '( )'
  SOLID_CELL_VISUAL = '[=]'

  attr_reader :solid

  def initialize
    clear
  end

  def to_s
    visual.center CELL_VISUAL_SIZE
  end

  def clear
    self.solid = false
    self.visual = EMPTY_CELL_VISUAL
  end

  def shape_fill
    self.visual = FILLED_CELL_VISUAL
  end

  def shape_center_fill
    self.visual = CENTER_CELL_VISUAL
  end

  def shade
    self.visual = SHADOW_CELL_VISUAL
  end

  def solidify
    self.solid = true
    self.visual = SOLID_CELL_VISUAL
  end

  def solid?
    @solid
  end

  private

  attr_writer :solid

  attr_accessor :visual
end

class Grid
  GRID_BORDER_VERT = '||'
  GRID_BORDER_HORIZ = '='
  GRID_DEFAULT_WIDTH = 10
  GRID_DEFAULT_HEIGHT = 20

  attr_reader :height, :width, :board_visual_width

  def initialize(width = GRID_DEFAULT_WIDTH, height = GRID_DEFAULT_HEIGHT)
    @board_visual_width = (width * Cell::CELL_VISUAL_SIZE) +
                          (GRID_BORDER_VERT.size * 2)
    @width = width
    @height = height
    @coordinate = init_coordinate
  end

  def to_s
    vertical_visual = grid_vertical_visual
    "#{vertical_visual}\n#{grid_playable_visual}\n#{vertical_visual}"
  end

  def draw_shape(shape)
    draw_shadow(shape)

    shape.filled_coords.each do |coord|
      cell = find_cell(coord)
      cell&.shape_fill
    end

    draw_shape_center(shape)
  end

  def draw_shadow(shape)
    projected_landing_coords(shape).each do |shadow_coord|
      cell = find_cell(shadow_coord)
      cell&.shade
    end
  end

  def draw_shape_center(shape)
    center_coordinates = shape.absolute_center_coord
    return unless center_coordinates

    cell = find_cell(center_coordinates)
    cell&.shape_center_fill
  end

  def undraw_shape(shape)
    clear_coords = shape.filled_coords | projected_landing_coords(shape)
    clear_coords.each do |coord|
      cell = find_cell(coord)
      cell&.clear
    end
  end

  def solidify_shape(shape)
    shape.filled_coords.each do |coord|
      cell = find_cell(coord)
      cell&.solidify
    end
  end

  def row_full?(row_y_value)
    row = coordinate[row_y_value]
    row.values.all?(&:solid?)
  end

  def clear_row!(row_y_value)
    row = coordinate[row_y_value]
    row.values.each(&:clear)
  end

  def deep_clear_row!(row_y_value)
    coordinate[row_y_value] = init_row_columns
  end

  def move_row_from_to(row_number, move_to)
    coordinate[move_to] = coordinate[row_number]
    coordinate[row_number] = init_row_columns
  end

  def shape_move_x?(shape, direction_sign = 1)
    shape.filled_coords.none? do |adjacent_coord|
      adjacent_coord[:x] += 1 * direction_sign
      coord_out_bounds?(adjacent_coord) || !!find_cell(adjacent_coord)&.solid?
    end
  end

  def shape_invalid_position?(shape)
    shape_out_bounds?(shape) || shape_touching_solid?(shape)
  end

  def shape_touching_solid?(shape)
    shape.filled_coords.any? { |coord| coord_touching_solid?(coord) }
  end

  def shape_out_bounds?(shape)
    shape.filled_coords.any? { |coord| coord_out_bounds?(coord) }
  end

  def coord_touching_solid?(coord)
    return true if coord_touching_bottom?(coord)
    return true if find_cell(coord)&.solid?

    coord_under = coord.dup
    coord_under[:y] += 1

    cell = find_cell(coord_under)
    !!cell&.solid?
  end

  def coord_touching_bottom?(coord)
    coord[:y] == height
  end

  def coord_out_bounds?(coord)
    coord[:y] <= 0 || coord[:y] > height ||
      coord[:x] <= 0 || coord[:x] > width
  end

  def [](row_y_value)
    coordinate[row_y_value]
  end

  def []=(row_y_value, new_row)
    coordinate[row_y_value] = new_row
  end

  private

  def projected_landing_coords(shape)
    original_position = shape.position.dup
    shape.position[:y] += 1 until shape_invalid_position?(shape)

    landing_coords = shape.filled_coords
    shape.position = original_position
    landing_coords
  end

  def find_cell(coord)
    return nil if coord_out_bounds?(coord)

    coordinate[coord[:y]][coord[:x]]
  end

  def grid_vertical_visual
    GRID_BORDER_HORIZ * board_visual_width
  end

  def grid_playable_visual
    coordinate.values.map do |row|
      "#{GRID_BORDER_VERT}#{row.values.join}#{GRID_BORDER_VERT}"
    end.join "\n"
  end

  def init_coordinate
    coordinate = Hash.new
    (1..height).each do |y|
      coordinate[y] = init_row_columns
    end
    coordinate
  end

  def init_row_columns
    (1..width).to_h { |x_pos| [x_pos, Cell.new] }
  end

  attr_reader :coordinate
end
