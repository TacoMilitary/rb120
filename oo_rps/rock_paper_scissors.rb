require 'pry-byebug'

HUMAN_IDENTITY = :human
COMPUTER_IDENTITY = :computer

COMPUTER_DISPLAY_NAME = 'Computer'.freeze
DEFAULT_HUMAN_DISPLAY_NAME = 'Human'.freeze

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

    puts 'What do you want to be called?'
    self.name = format_name(gets.chomp)
  end

  private

  def format_name(string)
    string.split.map(&:capitalize).join ' '
  end

  def prompt_move
    loop do
      puts 'Please choose rock, paper, or scissors:'
      found_move = Move.find_move(gets.chomp.strip)
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

class Move
  VALID_MOVES = %w(rock paper scissors).map(&:freeze).freeze
  WINNING_MOVES = {
                    'rock' => 'scissors',
                    'paper' => 'rock',
                    'scissors' => 'paper'
                  }.freeze

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
    WINNING_MOVES[rps_choice] == other_move.rps_choice
  end

  def ties?(other_move)
    rps_choice == other_move.rps_choice
  end

  protected

  attr_reader :rps_choice
end

class RPSGame
  TIE_MESSAGE = "It's a tie!"

  def initialize
    @human = Player.new
    @computer = Player.new COMPUTER_IDENTITY
  end

  def play
    human.ask_name
    display_welcome_message

    loop do
      human.choose
      computer.choose
      display_match_results
      break unless play_again?
    end

    display_goodbye_message
  end

  private

  attr_reader :human, :computer

  def display_welcome_message
    puts "Hello #{human}! Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    puts 'Goodbye! See you next time!'
  end

  def display_match_results
    human_move = human.move
    cpu_move = computer.move

    puts "#{human} chose #{human_move}."
    puts "The #{computer} chose #{cpu_move}."

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

  def play_again?
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.strip.downcase
      return answer == 'y' if ['y', 'n'].include?(answer)
      puts 'Sorry, must be y or n.'
    end
  end
end

RPSGame.new.play
