class GridSquare
  SQUARE_SIZE = 3
  EMPTY_SQUARE_VISUAL = '-'
  FILLED_SQUARE_VISUAL = '[ ]'

  def initialize
    @visual = EMPTY_SQUARE_VISUAL
    @visual = FILLED_SQUARE_VISUAL if rand(1..30) <= 2
  end

  def to_s
    visual.center SQUARE_SIZE
  end

  private

  attr_reader :visual
end

class Grid
  def initialize(width = 20, height = 35)
    @coordinate = init_coordinate(width, height)
  end

  def to_s
    coordinate.values.map do |row|
      row.values.join
    end.join "\n"
  end

  private

  def init_coordinate(width, height)
    coordinate = Hash.new
    (1..height).each do |x|
      coordinate[x] = Hash.new
      (1..width).each { |y| coordinate[x][y] = GridSquare.new }
    end
    coordinate
  end

  attr_reader :coordinate
end

puts Grid.new
