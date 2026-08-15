require 'yaml'

require_relative 'tetris_shapes'

# rubocop:disable Style/OneClassPerFile

module CLI
  DEFAULT_PROMPT = 'Please enter text:'
  DEFAULT_ERROR = 'Unknown error!'
  SCREEN_DIVIDER = "\n------------------------\n\n"

  def self.divide_screen
    print SCREEN_DIVIDER
  end

  def self.clear_screen
    system('clear') || system('cls') || divide_screen
  end

  def self.user_input
    print "> "
    gets.chomp.strip.downcase
  end

  def self.prompt(message = DEFAULT_PROMPT)
    puts message
    divide_screen
    user_input
  end

  def self.error(message = DEFAULT_ERROR)
    divide_screen
    puts "[ERROR]: #{message}"
    divide_screen
  end
end

module TetrisText
  TEXTS = YAML.load_file('tetris.yml')

  def self.[](key)
    TEXTS[key.to_s]
  end
end

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
    shape.filled_coords.each do |coord|
      cell = find_cell(coord)
      cell&.shape_fill
    end

    draw_shape_center(shape)
  end

  def draw_shadow(shape)
    shape.filled_x_coords
  end

  def draw_shape_center(shape)
    center_coordinates = shape.absolute_center_coord
    return unless center_coordinates

    cell = find_cell(center_coordinates)
    cell&.shape_center_fill
  end

  def undraw_shape(shape)
    shape.filled_coords.each do |coord|
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

  attr_reader :visual, :limbs, :position, :center_limb, :rotation_center

  def initialize(shape_data)
    limb_data = shape_data[TetrisShapes::LIMB_DATA]

    @visual = create_visual(limb_data)
    @limbs = translate_string_to_limbs(limb_data)
    @position = DEFAULT_POSITION.dup
    @rotation_center = shape_data[TetrisShapes::ROTATE_CENTER]
    @center_limb = find_center_limb
  end

  def filled_coords
    limbs.map { |limb| limb_absolute_coord(limb) }
  end

  def filled_x_coords
    filled_coords.each_with_object(Set.new) { |coord, set| set << coord[:x] }
  end

  def rotate(rotation_direction = CLOCKWISE_SIGN)
    return unless can_rotate?

    limbs.each { |limb| rotate_limb!(limb, rotation_direction) }
    fix_rotation_offset
  end

  def absolute_center_coord
    return nil unless can_rotate?

    limb_absolute_coord(center_limb)
  end

  alias to_s visual

  private

  def can_rotate?
    !!rotation_center
  end

  def fix_rotation_offset
    y_offset = center_limb[:y] - rotation_center[:y]
    x_offset = center_limb[:x] - rotation_center[:x]

    limbs.each do |limb|
      limb[:y] -= y_offset
      limb[:x] -= x_offset
    end
  end

  def rotate_limb!(limb, rotation_direction = CLOCKWISE_SIGN)
    previous_y = limb[:y]
    previous_x = limb[:x]
    limb[:y] = previous_x * -rotation_direction
    limb[:x] = previous_y * rotation_direction
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

  def find_center_limb
    return nil unless can_rotate?

    limbs.find { |limb| limb == rotation_center }
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

class Player
  ACTION_PROMPT = TetrisText[:tetromino_control_prompt]
  INVALID_ACTION = 'That is not a valid action!'

  FALL_ACTION = :fall
  MOVE_LEFT_ACTION = :move_left
  MOVE_RIGHT_ACTION = :move_right
  ROTATE_CLOCKWISE_ACTION = :rotate_clockwise
  ROTATE_COUNTER_ACTION = :rotate_counter_clockwise
  FREEFALL_ACTION = :freefall

  INPUTS_FOR_ACTIONS = {
    ['<', ','] => MOVE_LEFT_ACTION,
    ['>', '.'] => MOVE_RIGHT_ACTION,
    ['a'] => ROTATE_CLOCKWISE_ACTION,
    ['d'] => ROTATE_COUNTER_ACTION,
    ['s'] => FREEFALL_ACTION
  }.freeze

  def prompt_tetromino_action
    puts ACTION_PROMPT
    CLI.divide_screen

    loop do
      action = find_action(CLI.user_input)
      return action if action

      CLI.error(INVALID_ACTION)
    end
  end

  private

  def find_action(player_input)
    return FALL_ACTION if player_input.empty?

    INPUTS_FOR_ACTIONS.keys.each do |input_list|
      return INPUTS_FOR_ACTIONS[input_list] if input_list.include? player_input
    end

    nil
  end
end

class TetrisGame
  TITLE_PLATE = '] TETRIS ['
  TITLE_DECOR = '-'

  TUTORIAL_ANSWER = 'tutorial'
  START_ANSWER = 'start'
  INVALID_CHOICE = 'Invalid answer!'

  ACTION_TIME_STEP = :step
  ACTION_DONT_STEP = :dont_step
  ACTION_KILL_TETROMINO = :kill

  TIME_AFTER_ACTION = 0.1
  CELL_FALL_TIME = 0.05
  TETROMINO_FREEFALL_WAIT = 0.025
  TETROMINO_DEATH_WAIT = 0.75

  LEFT_DIRECTION = -1
  RIGHT_DIRECTION = 1

  AFTER_TUTORIAL_TEXT = TetrisText[:after_tutorial] % START_ANSWER

  TUTORIAL_TEXT = format(
    TetrisText[:tutorial],
    Cell::EMPTY_CELL_VISUAL,
    Cell::FILLED_CELL_VISUAL,
    Cell::CENTER_CELL_VISUAL,
    Cell::SHADOW_CELL_VISUAL,
    Cell::SOLID_CELL_VISUAL
  )

  WELCOME_TEXT = format(
    TetrisText[:welcome],
    TUTORIAL_ANSWER,
    START_ANSWER
  )

  def play
    intro_sequence
    begin_new_game
  end

  private

  attr_reader :grid, :player
  attr_accessor :shape

  def reset_game
    @grid = Grid.new
    @shape = nil
    @player = Player.new
  end

  def intro_sequence
    CLI.clear_screen
    start_or_tutorial
  end

  def start_or_tutorial
    puts WELCOME_TEXT
    CLI.divide_screen

    loop do
      answer = CLI.user_input

      tutorial_answer_loop if answer == TUTORIAL_ANSWER
      break if [TUTORIAL_ANSWER, START_ANSWER].include? answer

      CLI.error INVALID_CHOICE
    end
  end

  def tutorial_answer_loop
    CLI.clear_screen
    puts TUTORIAL_TEXT
    CLI.divide_screen
    loop do
      answer = CLI.prompt(AFTER_TUTORIAL_TEXT)
      break if answer == START_ANSWER

      CLI.error INVALID_CHOICE
    end
  end

  def begin_new_game
    CLI.clear_screen
    reset_game
    tetris_match_loop
  end

  def tetris_match_loop
    loop do
      self.shape = TetrisShapes.random_shape
      tetromino_control_loop unless tetromino_stop_control?
      tetromino_die
      sleep TETROMINO_DEATH_WAIT
      clear_full_rows
    end
  end

  def tetromino_control_loop
    loop do
      draw_shape_and_display_grid

      sleep TIME_AFTER_ACTION
      action_result = player_action_loop

      break if action_result == ACTION_KILL_TETROMINO

      tetromino_fall_step

      break if tetromino_stop_control?
    end
  end

  def tetromino_stop_control?
    grid.shape_touching_solid? shape
  end

  def tetromino_die
    grid.solidify_shape shape
    display_grid
  end

  def tetromino_fall_step
    draw_shape_and_display_grid
    sleep TIME_AFTER_ACTION
    tetromino_descend
  end

  def player_action_loop
    loop do
      player_action = player.prompt_tetromino_action
      action_result = perform_player_action(player_action)

      break action_result unless action_result == ACTION_DONT_STEP

      draw_shape_and_display_grid
    end
  end

  def perform_player_action(player_action)
    case player_action
    when Player::FALL_ACTION then tetromino_descend
    when Player::MOVE_LEFT_ACTION then tetromino_move_left
    when Player::MOVE_RIGHT_ACTION then tetromino_move_right
    when Player::FREEFALL_ACTION then tetromino_freefall
    when Player::ROTATE_CLOCKWISE_ACTION
      try_rotate_tetromino Shape::CLOCKWISE_SIGN
    when Player::ROTATE_COUNTER_ACTION
      try_rotate_tetromino Shape::COUNTER_CLOCKWISE_SIGN
    end
  end

  def tetromino_move_left
    tetromino_move_x LEFT_DIRECTION
  end

  def tetromino_move_right
    tetromino_move_x RIGHT_DIRECTION
  end

  def tetromino_move_x(direction_sign = RIGHT_DIRECTION)
    return ACTION_DONT_STEP unless grid.shape_move_x?(shape, direction_sign)
    shape.position[:x] += 1 * direction_sign
  end

  def tetromino_descend
    shape.position[:y] += 1
  end

  def try_rotate_tetromino(rotation_sign = Shape::CLOCKWISE_SIGN)
    shape.rotate(rotation_sign)
    shape.rotate(-rotation_sign) if grid.shape_invalid_position?(shape)

    ACTION_DONT_STEP
  end

  def tetromino_freefall
    until tetromino_stop_control?
      tetromino_descend
      draw_shape_and_display_grid
      sleep TETROMINO_FREEFALL_WAIT
    end
    ACTION_KILL_TETROMINO
  end

  def clear_full_rows
    lowest_empty_row = nil
    (1..grid.height).reverse_each do |row_number|
      if grid.row_full?(row_number)
        clear_row!(row_number)
        lowest_empty_row ||= row_number
      elsif lowest_empty_row
        row_fall_to!(row_number, lowest_empty_row)
        lowest_empty_row -= 1
      end
    end
  end

  def row_fall_to!(from_row, to_row)
    row = grid[from_row]
    return if no_solid_cells_in_row?(row)

    empty_row = grid[to_row]

    (1..grid.width).each do |x_pos|
      next unless row[x_pos].solid?

      empty_row[x_pos] = row[x_pos]
      row[x_pos] = Cell.new
      display_grid
      sleep CELL_FALL_TIME
    end
  end

  def clear_row!(row_y)
    (1..grid.width).each do |x_pos|
      cell = grid[row_y][x_pos]
      next unless cell.solid?

      cell.clear
      display_grid
      sleep CELL_FALL_TIME
    end
  end

  def no_solid_cells_in_row?(row)
    row.values.none?(&:solid?)
  end

  def display_grid
    grid_visual_size = grid.board_visual_width
    centered_title = TITLE_PLATE.center(grid_visual_size, TITLE_DECOR)

    CLI.clear_screen
    puts "#{centered_title}\n\n"
    puts grid
    puts "\n#{TITLE_DECOR * grid_visual_size}"
    puts
  end

  def draw_shape_and_display_grid
    grid.draw_shape(shape)
    display_grid
    grid.undraw_shape(shape)
  end
end

# rubocop:enable Style/OneClassPerFile

TetrisGame.new.play
