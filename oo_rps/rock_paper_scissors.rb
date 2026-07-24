HUMAN_IDENTITY = :human
COMPUTER_IDENTITY = :computer
WIN_IDENTITY = :win
LOSE_IDENTITY = :lose
TIE_IDENTITY = :equal

COMPUTER_DISPLAY_NAME = 'Computer'.freeze
DEFAULT_HUMAN_DISPLAY_NAME = 'Human'

MOVES = %w(rock paper scissors).map!(&:freeze).freeze
WINNING_MOVES = {
                  'rock' => 'scissors',
                  'paper' => 'rock',
                  'scissors' => 'paper'
                }.freeze

class Player
  attr_reader :move
  attr_accessor :name

  def initialize(player_type = HUMAN_IDENTITY)
    @player_type = player_type
    @move = nil
    @name = human? ? DEFAULT_HUMAN_DISPLAY_NAME : COMPUTER_DISPLAY_NAME
  end

  def choose
    human? ? prompt_move : random_move
  end

  def human?
    @player_type == HUMAN_IDENTITY
  end

  def ask_name
    return nil unless human?

    puts 'What do you want to be called?'
    self.name = format_name(gets.chomp)
  end

  def compare_move(other_player)
    if WINNING_MOVES[move] == other_player.move
      WIN_IDENTITY
    elsif WINNING_MOVES[other_player.move] == move
      LOSE_IDENTITY
    else
      TIE_IDENTITY
    end
  end

  private

  def format_name(string)
    string.split.map(&:capitalize).join ' '
  end

  def random_move
    @move = MOVES.sample
  end

  def prompt_move
    loop do
      puts 'Please choose rock, paper, or scissors:'
      input = gets.chomp.strip

      if MOVES.include? input
        @move = input
        break
      end

      puts 'Sorry. Invalid choice!'
    end
  end
end

class RPSGame
  TIE_MESSAGE = "It's a tie!"
  LOSE_MESSAGE = 'Computer won!'

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
      display_winner
      break unless play_again?
    end

    display_goodbye_message
  end

  private

  attr_reader :human, :computer

  def display_welcome_message
    puts "Hello #{human.name}! Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    puts 'Goodbye! See you next time!'
  end

  # rubocop:disable Metrics/AbcSize
  def display_winner
    puts "#{human.name} chose #{human.move.upcase}."
    puts "The Computer chose #{computer.move.upcase}."

    case human.compare_move(computer)
    when WIN_IDENTITY then puts "#{human.name} won!"
    when LOSE_IDENTITY then puts LOSE_MESSAGE
    else puts TIE_MESSAGE
    end
  end
  # rubocop:enable Metrics/AbcSize

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
