require 'yaml'

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