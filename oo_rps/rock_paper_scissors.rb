require 'pry-byebug'

HUMAN_IDENTITY = :human
COMPUTER_IDENTITY = :computer

COMPUTER_DISPLAY_NAME = %w(Computer R2D2 Smoke T-Dawg Franklin).sample.freeze
DEFAULT_HUMAN_DISPLAY_NAME = 'Human'.freeze

CLI_DIVIDER = "\n\n==================\n"

def divide_screen
  print CLI_DIVIDER
end

def clear_screen
  system('clear') || system('cls') || divide_screen
end

def generic_prompt(message = 'Please input text:')
  puts message
  print '> '
  gets.chomp.strip.downcase
end

class Player
  attr_reader :move
  attr_accessor :name

  def initialize(player_type = HUMAN_IDENTITY)
    @player_type = player_type
    @move = nil
    @name = default_name
  end

  def choose
    chosen_move = human? ? prompt_move : Move.random_move
    @move = chosen_move
  end

  def human?
    @player_type == HUMAN_IDENTITY
  end

  def ask_name
    return nil unless human?

    answer = generic_prompt('What do you want to be called?')
    self.name = format_name(answer)
  end

  private

  def format_name(string)
    string.split.map(&:capitalize).join ' '
  end

  def prompt_move
    loop do
      prompt = 'Please choose rock, paper, scissors, lizard, or spock:'
      choice = generic_prompt(prompt)
      found_move = Move.find_move(choice)
      return found_move if found_move

      puts 'Sorry. Invalid choice!'
    end
  end

  def default_name
    human? ? DEFAULT_HUMAN_DISPLAY_NAME : COMPUTER_DISPLAY_NAME
  end

  def to_s
    name
  end
end

class Computer

end

class Move
  VALID_MOVES = %w(rock paper scissors lizard spock).map(&:freeze).freeze
  # rubocop:disable Layout/FirstHashElementIndentation
  WINNING_MOVES = {
                    'rock' => ['scissors', 'lizard'],
                    'paper' => ['rock', 'spock'],
                    'scissors' => ['paper', 'lizard'],
                    'lizard' => ['spock', 'paper'],
                    'spock' => ['scissors', 'rock']
                  }.freeze
  # rubocop:enable Layout/FirstHashElementIndentation

  def self.random_move
    Move.new VALID_MOVES.sample
  end

  def self.find_move(string)
    return nil if string.empty?

    found_choice = VALID_MOVES.find do |choice|
      choice.start_with?(string) || string.start_with?(choice)
    end

    Move.new(found_choice) if found_choice
  end

  def initialize(rps_choice)
    @rps_choice = rps_choice
  end

  def to_s
    rps_choice.upcase
  end

  def beats?(other_move)
    winning_move = WINNING_MOVES[rps_choice]

    if winning_move.is_a? Array
      winning_move.include? other_move.rps_choice
    else
      winning_move == other_move.rps_choice
    end
  end

  def ties?(other_move)
    rps_choice == other_move.rps_choice
  end

  protected

  attr_reader :rps_choice
end

class RPSGame
  GRAND_WIN_SCORE = 10
  TIE_MESSAGE = "It's a tie!"

  def initialize
    @human = Player.new
    @computer = Player.new COMPUTER_IDENTITY
    reset_game
  end

  # rubocop:disable Metrics/MethodLength
  def play
    clear_screen
    intro_sequence

    loop do
      play_round
      if grand_winner?
        display_history

        divide_screen
        display_grand_winner

        divide_screen
        break unless play_again?
        clear_screen
        reset_game
      end
    end

    clear_screen
    display_goodbye_message
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_reader :human, :computer, :human_score, :cpu_score, :round_history

  def reset_game
    @human_score = 0
    @cpu_score = 0
    @round_history = []
  end

  def round_count
    round_history.size.next
  end

  def intro_sequence
    human.ask_name

    divide_screen
    display_welcome_message
  end

  def play_round
    display_scores
    human.choose
    computer.choose

    clear_screen # divide_screen
    display_match_results
    increment_score

    divide_screen
  end

  def display_welcome_message
    puts "Hello #{human}! Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    display_grand_winner
    display_scores
    puts 'Goodbye! See you next time!'
  end

  # rubocop:disable Layout/LineLength
  def add_round_to_history(human_move, cpu_move)
    round_history << "Round: #{round_count} -[ #{computer}: #{cpu_move} | #{human}: #{human_move} ]"
  end
  # rubocop:enable Layout/LineLength

  def display_history
    puts round_history
  end

  def display_match_results
    human_move = human.move
    cpu_move = computer.move

    puts "#{human} chose #{human_move}."
    puts "The #{computer} chose #{cpu_move}."
    add_round_to_history(human_move, cpu_move)

    puts winner_text(human_move, cpu_move)
  end

  def winner_text(human_move, cpu_move)
    if human_move.beats?(cpu_move)
      "#{human} won!"
    elsif cpu_move.beats?(human_move)
      "#{computer} won!"
    else
      TIE_MESSAGE
    end
  end

  def increment_score
    human_move = human.move
    cpu_move = computer.move

    if human_move.beats?(cpu_move)
      @human_score += 1
    elsif cpu_move.beats?(human_move)
      @cpu_score += 1
    end
  end

  def display_scores
    puts "#{computer}: #{cpu_score} || #{human}: #{human_score}"
  end

  def grand_winner?
    human_score >= GRAND_WIN_SCORE || cpu_score >= GRAND_WIN_SCORE
  end

  def display_grand_winner
    if human_score >= GRAND_WIN_SCORE
      puts "#{human} wins this tournament!"
    else
      puts "#{computer} wins this tournament!"
    end
  end

  def play_again?
    loop do
      answer = generic_prompt('Would you like to play again? (y/n)')
      return answer == 'y' if ['y', 'n'].include?(answer)

      puts 'Sorry, must be y or n.'
    end
  end
end

RPSGame.new.play
