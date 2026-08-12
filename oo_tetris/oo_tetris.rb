class GridSquare
  SQUARE_SIZE = 3
  EMPTY_SQUARE_VISUAL = '-'
  FILLED_SQUARE_VISUAL = '[ ]'

  attr_reader :filled

  def initialize
    clear
    fill if rand(1..30) <= 2
  end

  def to_s
    visual.center SQUARE_SIZE
  end

  def clear
    self.filled = false
    self.visual = EMPTY_SQUARE_VISUAL
  end

  def fill
    self.filled = true
    self.visual = FILLED_SQUARE_VISUAL
  end

  private

  attr_writer :filled

  attr_accessor :visual
end

class Grid
  GRID_BORDER_VERT = '||'
  GRID_BORDER_HORIZ = '='

  def initialize(width = 20, height = 35)
    @board_visual_width = (width * GridSquare::SQUARE_SIZE) +
                          (GRID_BORDER_VERT.size * 2)
    @coordinate = init_coordinate(width, height)
  end

  def to_s
    vertical_visual = grid_vertical_visual
    "#{vertical_visual}\n#{grid_playable_visual}\n#{vertical_visual}"
  end

  private

  def grid_vertical_visual
    GRID_BORDER_HORIZ * board_visual_width
  end

  def grid_playable_visual
    coordinate.values.map do |row|
      "#{GRID_BORDER_VERT}#{row.values.join}#{GRID_BORDER_VERT}"
    end.join "\n"
  end

  def init_coordinate(width, height)
    coordinate = Hash.new
    (1..height).each do |x|
      coordinate[x] = Hash.new
      (1..width).each { |y| coordinate[x][y] = GridSquare.new }
    end
    coordinate
  end

  attr_reader :coordinate, :board_visual_width
end

puts Grid.new
