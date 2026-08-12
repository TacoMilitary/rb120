# require 'pry-byebug'

HUMAN_IDENTITY = :human
COMPUTER_IDENTITY = :computer

VALID_MOVES = %w(rock paper scissors lizard spock).map(&:freeze).freeze

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

class Personality
  DEFAULT_MOVE_CHANCE = 100

  attr_reader :name, :move_chances

  def initialize(name, move_chances = {})
    @name = name
    @move_chances = init_move_chances(move_chances)
  end

  def decide_move
    loop do
      random_move = VALID_MOVES.sample
      probability = move_chances[random_move]
      return random_move if rand(1..100) <= probability
    end
  end

  private

  def init_move_chances(move_chances)
    default_value = move_chances[:default] || DEFAULT_MOVE_CHANCE
    default_chances = VALID_MOVES.map { |move| [move, default_value] }.to_h
    default_chances.merge! move_chances
  end
end

PERSONALITIES = [
                  Personality.new('R2D2', 'rock' => 100, default: 0),
                  Personality.new('Hal', 'scissors' => 100, 'rock' => 15, 'paper' => 0, default: 60),
                  Personality.new('Computer'),
                  Personality.new('Lizard Himself', 'lizard' => 100, default: 30),
                  Personality.new('Bob', 'paper' => 70, 'rock' => 0, 'lizard' => 0)
                ]

class GenericPlayer
  DEFAULT_DISPLAY_NAME = 'Player'.freeze

  attr_reader :move
  attr_accessor :name

  def initialize
    @move = nil
    @name = set_name
  end

  def set_name
    DEFAULT_DISPLAY_NAME
  end

  def to_s
    name
  end
end

class Player < GenericPlayer
  def choose
    @move = prompt_move
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

  def ask_name
    answer = generic_prompt('What do you want to be called?')
    self.name = format_name(answer)
  end

  private

  def format_name(string)
    string.split.map(&:capitalize).join ' '
  end
end

class Computer < GenericPlayer
  attr_reader :personality

  def initialize
    super
    randomize_personality
    @name = personality.name
  end

  def choose
    @move = Move.new(personality.decide_move)
  end

  def randomize_personality
    @personality = PERSONALITIES.sample
  end
end

class Move
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
    @human = Player.new
    @computer = Computer.new
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
