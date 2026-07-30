module CLIUtils
  SCREEN_DIVIDER = "\n-------------------\n"
  def self.divide_screen
    print SCREEN_DIVIDER
  end

  def self.clear_screen
    system('clear') || system('cls') || divide_screen
  end

  def self.prompt(message)
    puts message
    print '> '
    gets.chomp.strip.downcase
  end

  def self.error_message(message = 'Unknown error!')
    puts "[ERROR]: #{message}"
    divide_screen
  end

  def self.multiple_choice(choices)
    case choices.size
    when 0 then 'None'
    when 1 then choices.first.to_s
    when 2 then "#{choices.first} or #{choices.last}"
    else
      joined_string = choices[...-1].join ', '
      joined_string << ", or #{choices.last}"
      joined_string
    end
  end
end

class Board
  INITIAL_MARKER = ' '
  WINNING_LINES =
    [
      [1, 2, 3], # Horizontals
      [4, 5, 6],
      [7, 8, 9],

      [1, 4, 7], # Verticals
      [2, 5, 8],
      [3, 6, 9],

      [1, 5, 9], # Diagonals
      [3, 5, 7]
    ]

  def initialize
    @squares = init_squares
  end

  def display
    square_vals = squares.values

    puts ''
    puts board_row(square_vals[0..2])
    puts BOARD_ROW_SEPARATOR
    puts board_row(square_vals[3..5])
    puts BOARD_ROW_SEPARATOR
    puts board_row(square_vals[6..8])
    puts ''
  end

  def square_empty?(square)
    squares[square] == INITIAL_MARKER
  end

  def square_marked?(square)
    !square_empty?(square)
  end

  def mark_square(square, marker)
    squares[square] = marker
  end

  def []=(square, marker)
    mark_square(square, marker)
  end

  def empty_squares
    squares.keys.select { |square| square_empty?(square) }
  end

  def full?
    empty_squares.empty?
  end

  def line_has_winner?(line)
    compare_marker = squares[line.first]
    line.all? do |square|
      square_marked?(square) && squares[square] == compare_marker
    end
  end

  def winning_marker
    WINNING_LINES.each do |line|
      return squares[line.first] if line_has_winner?(line)
    end
    nil
  end

  private

  attr_reader :squares

  def init_squares
    new_squares = {}
    (1..9).each { |number| new_squares[number] = INITIAL_MARKER }
    new_squares
  end

  BOARD_ROW_SEPARATOR = '-----+-----+-----'.freeze
  SQUARE_SIZE = 5
  EMPTY_ROW = '     |     |     '.freeze

  def board_line(markers)
    markers.map { |marker| marker.center(SQUARE_SIZE) }.join '|'
  end

  def board_row(markers)
    [
      EMPTY_ROW,
      board_line(markers),
      EMPTY_ROW
    ].join "\n"
  end
end

# GenericPlayer = Struct.new('GenericPlayer', :marker)

class GenericPlayer
  @@players_initialized = 0
  DEFAULT_NAME = 'Player'

  attr_accessor :marker, :name

  def initialize
    @@players_initialized += 1
    @marker = nil
    @name = init_name
  end

  def to_s
    name
  end

  def upcase
    to_s.upcase
  end

  private

  def init_name
    "#{DEFAULT_NAME} #{@@players_initialized}"
  end
end

class Human < GenericPlayer
  def take_turn!(board)
    loop do
      choices_list = CLIUtils.multiple_choice(board.empty_squares)
      choice_text = "Choose a square #{choices_list}:"
      answer = CLIUtils.prompt(choice_text).to_i
      if board.square_empty?(answer)
        board[answer] = marker
        return
      end
      CLIUtils.error_message("That's not a valid square!")
    end
  end

  def ask_name
    loop do
      new_name = CLIUtils.prompt('What would you like to be called?')
      unless new_name.empty?
        self.name = format_name(new_name)
        return
      end
      CLIUtils.error_message('That is not a valid name!')
    end
  end

  def ask_marker(marker_choices)
    loop do
      ask_text = marker_asking_text(marker_choices)
      answer = CLIUtils.prompt(ask_text)

      possible_marker = find_marker(marker_choices, answer)
      if possible_marker
        self.marker = possible_marker
        return
      end

      CLIUtils.error_message("That's not a valid choice!")
    end
  end

  private

  def marker_asking_text(marker_choices)
    markers_list = CLIUtils.multiple_choice(marker_choices)
    "What marker do you want to use? (#{markers_list})"
  end

  def find_marker(marker_choices, chosen_marker)
    marker_choices.find { |marker| marker.casecmp? chosen_marker }
  end

  def format_name(string)
    string.split.map(&:capitalize).join ' '
  end
end

class Computer < GenericPlayer
  NAMES = ['Joshua', 'CPU', 'R2-D2', 'Computer', 'K-9', 'C-3PO']

  def take_turn!(board)
    random_square = board.empty_squares.sample
    board[random_square] = marker
  end

  private

  def init_name
    NAMES.sample
  end
end

class TTTGame
  MARKERS = ['X', 'O']
  CONTINUE_STATE = :continue_game
  TOURNAMENT_WIN_SCORE = 5
  TIE_STATE = :tie
  WIN_STATE = :win
  LOSE_STATE = :lose

  def initialize
    @human = Human.new
    reset_tournament
    reset_match
  end

  def play
    intro_sequence

    CLIUtils.divide_screen
    loop do
      tournament_loop
      display_tournament_result
      break unless play_again?
      tournament_loop_cleanup
    end

    display_goodbye_message
    game_state
  end

  private

  attr_reader :board, :cpu, :human, :turn_queue
  attr_accessor :game_state, :human_score, :cpu_score, :last_match

  def intro_sequence
    CLIUtils.clear_screen
    display_welcome_message
    human.ask_name
    human.ask_marker MARKERS
    assign_cpu_marker
  end

  def remaining_markers
    MARKERS.reject { |marker| human.marker == marker || cpu.marker == marker }
  end

  def assign_cpu_marker
    cpu.marker = remaining_markers.sample
  end

  def tournament_loop_cleanup
    CLIUtils.clear_screen
    reset_tournament
    reset_match
    assign_cpu_marker
  end

  def play_again?
    prompt_text = 'Would you like to play another 5 rounds? ( Y / N )'
    answer = CLIUtils.prompt(prompt_text)
    answer.start_with? 'y'
  end

  def reset_match
    @board = Board.new
    @turn_queue = [human, cpu]
    @game_state = CONTINUE_STATE
  end

  def reset_tournament
    @cpu = Computer.new
    @human_score = 0
    @cpu_score = 0
    @last_match = nil
  end

  def tournament_winner?
    cpu_score == TOURNAMENT_WIN_SCORE || human_score == TOURNAMENT_WIN_SCORE
  end

  def tournament_loop
    loop do
      play_match
      break if tournament_winner?

      reset_match
      CLIUtils.clear_screen
    end
  end

  def play_match
    loop do
      display_board_and_last_match
      play_current_turn
      turn_end_evaluation

      break unless game_state == CONTINUE_STATE

      CLIUtils.clear_screen
    end

    CLIUtils.clear_screen
    display_turn_result
    sleep(1.5)
  end

  def turn_result
    return TIE_STATE if board.full?

    possible_winner = board.winning_marker
    return WIN_STATE if possible_winner == human.marker
    return LOSE_STATE if possible_winner == cpu.marker

    CONTINUE_STATE
  end

  def turn_end_evaluation
    self.game_state = turn_result
    return if game_state == CONTINUE_STATE

    self.last_match = turn_result_message
    increment_scores
  end

  def increment_scores
    case game_state
    when WIN_STATE then self.human_score += 1
    when LOSE_STATE then self.cpu_score += 1
    end
  end

  def display_board_and_last_match
    display_board
    return unless last_match

    puts "Last Match: #{last_match}\n\n"
    CLIUtils.divide_screen
  end

  def display_board
    puts "#{human.upcase}: #{human_score} | #{cpu.upcase}: #{cpu_score}"
    puts "- You are (#{human.marker}) | #{cpu.upcase} is (#{cpu.marker})"
    board.display
  end

  def display_tournament_result
    CLIUtils.divide_screen
    puts tournament_result_message
  end

  def play_current_turn
    next_up = turn_queue.first
    next_up.take_turn!(board)
    turn_queue.rotate!
  end

  def display_welcome_message
    puts 'Hello! Welcome to Tic Tac Toe!'
    CLIUtils.divide_screen
  end

  def display_goodbye_message
    CLIUtils.divide_screen
    puts "Thanks for playing, #{human}! Goodbye!\n\n"
  end

  def tournament_result_message
    case game_state
    when WIN_STATE
      "#{human} won the Tournament! #{human} won 5 rounds!"
    when LOSE_STATE
      "You lost the Tournament! #{cpu} wins!"
    end
  end

  def turn_result_message
    case game_state
    when TIE_STATE
      "The board was filled. It's a tie!"
    when WIN_STATE
      "#{human} won! #{human} got three squares in a row!"
    when LOSE_STATE
      "You lost! #{cpu} got three squares!"
    end
  end

  def display_turn_result
    display_board
    CLIUtils.divide_screen
    puts turn_result_message
  end
end

game = TTTGame.new
game.play
