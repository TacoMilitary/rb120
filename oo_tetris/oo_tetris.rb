require_relative 'tetris_utils'
require_relative 'grid_behavior'
require_relative 'shape_behavior'

# rubocop:disable Style/OneClassPerFile

class Player
  ACTION_PROMPT = TetrisText[:tetromino_control_prompt]
  INVALID_ACTION = 'That is not a valid action!'

  FALL_ACTION = :fall
  MOVE_LEFT_ACTION = :move_left
  MOVE_RIGHT_ACTION = :move_right
  ROTATE_CLOCKWISE_ACTION = :rotate_clockwise
  ROTATE_COUNTER_ACTION = :rotate_counter_clockwise
  FREEFALL_ACTION = :freefall

  PLAY_AGAIN_CHOICE = 'yes'

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

  def play_again?
    answer = CLI.prompt TetrisText[:play_again]
    answered_yes?(answer)
  end

  private

  def answered_yes?(answer)
    PLAY_AGAIN_CHOICE.start_with?(answer) ||
      answer.start_with?(PLAY_AGAIN_CHOICE)
  end

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

  FAIL_TETROMINO_SPAWN = :failed_spawn
  SUCESSFUL_TETROMINO_SPAWN = :spawned_tetromino

  TIME_AFTER_ACTION = 0.1
  CELL_FALL_TIME = 0.025
  TETROMINO_FREEFALL_WAIT = 0.025
  TETROMINO_DEATH_WAIT = 0.3

  LEFT_DIRECTION = -1
  RIGHT_DIRECTION = 1

  AFTER_TUTORIAL_TEXT = TetrisText[:after_tutorial] % START_ANSWER

  LOSE_TEXT = TetrisText[:lose]

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
    game_loop
  end

  private

  attr_reader :grid, :player
  attr_accessor :shape, :desired_spawn_x

  def reset_game
    @grid = Grid.new
    @shape = nil
    @player = Player.new
    @desired_spawn_x = grid.width / 2
  end

  def game_loop
    loop do
      game_sequence
      break unless player.play_again?
    end
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

  def game_sequence
    CLI.clear_screen
    reset_game
    tetris_match_loop
    display_match_loss
  end

  def tetris_match_loop
    loop do
      spawn_result = spawn_fitting_tetromino
      break if spawn_result == FAIL_TETROMINO_SPAWN

      tetromino_control_loop
      tetromino_die
      clear_full_rows
    end

    tetromino_die
    display_grid
  end

  def spawn_fitting_tetromino
    randomized_shapes = TetrisShapes.all_shapes.shuffle!

    randomized_shapes.each do |random_shape|
      self.shape = random_shape
      spawn_result = set_shape_spawn

      return spawn_result if spawn_result == SUCESSFUL_TETROMINO_SPAWN
    end

    FAIL_TETROMINO_SPAWN
  end

  def set_shape_spawn
    desired_spawns.each do |x_pos|
      shape.position[:x] = x_pos

      unless grid.shape_invalid_position?(shape)
        return SUCESSFUL_TETROMINO_SPAWN
      end
    end

    shape.position[:x] = desired_spawns.first
    FAIL_TETROMINO_SPAWN
  end

  def desired_spawns
    sort_distance_to_desired = proc { |x_pos| (desired_spawn_x - x_pos).abs }
    (1..grid.width).to_a.shuffle.sort_by(&sort_distance_to_desired)
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
    self.desired_spawn_x = shape.position[:x]
    sleep TETROMINO_DEATH_WAIT
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
    when Player::FALL_ACTION then ACTION_TIME_STEP
    when Player::MOVE_LEFT_ACTION then tetromino_move_left
    when Player::MOVE_RIGHT_ACTION then tetromino_move_right
    when Player::FREEFALL_ACTION then tetromino_freefall
    when Player::ROTATE_CLOCKWISE_ACTION
      rotate_tetromino Shape::CLOCKWISE_SIGN
    when Player::ROTATE_COUNTER_ACTION
      rotate_tetromino Shape::COUNTER_CLOCKWISE_SIGN
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
    ACTION_KILL_TETROMINO if tetromino_stop_control?
  end

  def tetromino_descend
    shape.position[:y] += 1
  end

  def rotate_tetromino(rotation_sign = Shape::CLOCKWISE_SIGN)
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

  def display_match_loss
    puts LOSE_TEXT
    CLI.divide_screen
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
