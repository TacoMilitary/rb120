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
    line.all? do|square| 
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
  EMPTY_ROW = '     |     |     '.freeze

  def board_line(markers)
    markers.map { |marker| "  #{marker}  " }.join '|'
  end

  def board_row(markers)
    [
      EMPTY_ROW,
      board_line(markers), 
      EMPTY_ROW
    ].join "\n"
  end
end

class GenericPlayer
  attr_reader :marker

  def initialize(marker)
    @marker = marker
  end
end

class Human < GenericPlayer
  def take_turn!(board)
    loop do
      choice_text = "Choose a square #{square_choices(board)}:"
      answer = CLIUtils.prompt(choice_text).to_i
      if board.square_empty?(answer)
        board[answer] = marker
        return
      end
      CLIUtils.error_message("That's not a valid square!")
    end
  end

  private

  def square_choices(board)
    available_choices = board.empty_squares

    case available_choices.size
    when 0 then 'None'
    when 1 then available_choices.first.to_s
    when 2 then "#{available_choices.first} or #{available_choices.last}"
    else
      joined_string = available_choices[...-1].join ', '
      joined_string << ", or #{available_choices.last}"
      joined_string
    end
  end
end

class Computer < GenericPlayer
  def take_turn!(board)
    random_square = board.empty_squares.sample
    board[random_square] = marker
  end
end

class TTTGame
  HUMAN_MARKER = 'X'
  CPU_MARKER = 'O'
  CONTINUE_STATE = :continue_game
  TOURNAMENT_WIN_SCORE = 5
  TIE_STATE = :tie
  WIN_STATE = :win
  LOSE_STATE = :lose

  def initialize
    reset_tournament
    reset_match
  end

  def play(tournmanent: false)
    CLIUtils.clear_screen
    display_welcome_message

    loop do
      tournament_loop
      display_tournament_result
      break unless play_again?
      reset_game
    end

    display_goodbye_message
    game_state
  end

  private

  attr_reader :board, :cpu, :human, :turn_queue
  attr_accessor :game_state, :human_score, :cpu_score, :last_match

  def reset_game
    CLIUtils.clear_screen
    reset_tournament
    reset_match
  end

  def play_again?
    prompt_text = 'Would you like to play another 5 rounds? ( Y / N )'
    answer = CLIUtils.prompt(prompt_text)
    answer.start_with? 'y'
  end

  def reset_match
    @board = Board.new
    @human = Human.new(HUMAN_MARKER)
    @cpu = Computer.new(CPU_MARKER)
    @turn_queue = [human, cpu]
    @game_state = CONTINUE_STATE
  end

  def reset_tournament
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
    puts "Your Score: #{human_score} | CPU Score: #{cpu_score}"
    puts "- You are (#{human.marker}) | CPU is (#{cpu.marker})"
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
    puts "Thanks for playing! Goodbye!\n\n"
  end

  def tournament_result_message
    case game_state
    when WIN_STATE
      "You've won the Tournament! You won 5 rounds!"
    when LOSE_STATE
      "You lost the Tournament! The Computer wins!"
    end
  end

  def turn_result_message
    case game_state
    when TIE_STATE then
      "The board was filled. It's a tie!"
    when WIN_STATE
      "You won! You got three squares in a row!"
    when LOSE_STATE
      "You lost! The Computer got three squares!"
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
