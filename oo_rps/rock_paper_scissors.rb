HUMAN_IDENTITY = :human
COMPUTER_IDENTITY = :computer
COMPUTER_DISPLAY_NAME = 'Computer'.freeze
DEFAULT_HUMAN_DISPLAY_NAME = 'Human'
MOVES = %w(rock paper scissors).map!(&:freeze).freeze

def format_name(string)
  string.split.map(&:capitalize).join ' '
end

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

  private

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

class Move
end

class Rule
end

def compare
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

  def display_winner
    puts "#{human.name} chose #{human.move.upcase}."
    puts "The Computer chose #{computer.move.upcase}."
    win_message = "#{human.name} won!"

    case human.move
    when 'rock'
      puts TIE_MESSAGE if computer.move == 'rock'
      puts win_message if computer.move == 'scissors'
      puts LOSE_MESSAGE if computer.move == 'paper'
    when 'paper'
      puts TIE_MESSAGE if computer.move == 'paper'
      puts win_message if computer.move == 'rock'
      puts LOSE_MESSAGE if computer.move == 'scissors'
    when 'scissors'
      puts TIE_MESSAGE if computer.move == 'scissors'
      puts win_message if computer.move == 'paper'
      puts LOSE_MESSAGE if computer.move == 'rock'
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
