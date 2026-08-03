require 'pry-byebug'

module CLI
  SCREEN_DIVIDER = "\n================\n\n"
  DEFAULT_PROMPT = 'Please enter text:'
  USER_PROMPT = '> '

  def self.divide_screen
    print SCREEN_DIVIDER
  end

  def self.clear_screen
    system('clear') || system('cls') || divide_screen
  end

  def self.prompt(message = DEFAULT_PROMPT)
    puts message
    print USER_PROMPT
    gets.chomp.strip.downcase
  end
end

class Card
  ACE_CARD_TYPE = 'a'
  ACE_CARD_VALUE = 11
  ACE_SPECIAL_VALUE = 1
  FACE_CARD_VALUE = 10
  FACE_CARDS = 'jqk'.chars
  NUMBER_CARDS = ('2'..'10')
  OBSCURED_CARD_VISUAL = '[?]'

  attr_reader :value

  def initialize(card_type)
    @card_visual = "[#{card_type.upcase}]"
    @value = init_value(card_type)
    @is_ace = value == ACE_CARD_VALUE
    @is_face_card = value == FACE_CARD_VALUE
  end

  def ace?
    @is_ace
  end

  def face_card?
    @is_face_card
  end

  def to_s
    card_visual
  end

  private

  attr_reader :card_visual

  def init_value(card_type)
    case card_type.downcase
    when *FACE_CARDS then FACE_CARD_VALUE
    when ACE_CARD_TYPE then ACE_CARD_VALUE
    else card_type.to_i
    end
  end
end

class StandardDeck
  CARD_VALUE_CONVERSION = proc { |value_card| Card.new value_card }

  FACE_CARDS = Card::FACE_CARDS.map(&CARD_VALUE_CONVERSION)
  VALUE_CARDS = Card::NUMBER_CARDS.map(&CARD_VALUE_CONVERSION)
  ACE_CARD = Card.new('A')

  SUITS_IN_DECK = 4
  SUIT = [*VALUE_CARDS, *FACE_CARDS, ACE_CARD].freeze

  def self.random_card
    SUIT.sample
  end

  attr_reader :cards

  def initialize
    @cards = new_mutable_deck
  end

  def draw
    random_index = rand(0...cards.size)
    cards.delete_at random_index
  end

  private

  def new_mutable_deck
    SUIT * SUITS_IN_DECK
  end
end

class Hand
  include Comparable

  def initialize
    @cards = [].freeze
  end

  def <=>(other)
    case other
    when Integer, Float then compare_sum(other)
    when Hand then compare_sum(other.sum)
    else raise(TypeError, "Can't compare #{self.class} to #{other.class}.")
    end
  end

  def <<(new_card)
    self.cards = [*cards, new_card].freeze
  end

  def to_s
    cards.join ' '
  end

  def obscured
    unknown_cards = ([Card::OBSCURED_CARD_VISUAL] * cards[1..].size).join ' '
    "#{cards.first} #{unknown_cards}".strip
  end

  def sum
    full_sum = cards.sum(&:value)

    return full_sum unless full_sum > BlackjackGame::TARGET_SUM

    ace_count = cards.count(&:ace?)
    sum_without_aces + (ace_count * Card::ACE_SPECIAL_VALUE)
  end

  def first_card_value
    first_card = cards.first
    return first_card.value unless first_card.ace?

    use_special_value = cards.sum(&:value) > BlackjackGame::TARGET_SUM
    return first_card.value unless use_special_value

    Card::ACE_SPECIAL_VALUE
  end

  private

  attr_accessor :cards

  def sum_without_aces
    cards.reject(&:ace?).sum(&:value)
  end

  def compare_sum(other_value)
    sum <=> other_value
  end
end

class Gambler
  DEFAULT_NAME = 'Gambler'

  attr_reader :hand, :name

  def initialize(name = self.class::DEFAULT_NAME)
    @name = name
    @hand = Hand.new
  end

  def bust?
    hand > BlackjackGame::TARGET_SUM
  end

  def blackjack?
    hand == BlackjackGame::TARGET_SUM
  end

  def unplayable_hand?
    bust? || blackjack?
  end

  def total
    hand.sum
  end

  def obscure_total
    hand.first_card_value
  end

  def obscure_hand
    hand.obscured
  end

  def <<(card)
    hand << card
  end

  def to_s
    name
  end
end

class Dealer < Gambler
  DEFAULT_NAME = 'Dealer'
end

class BlackjackGame
  TARGET_SUM = 21
  INITIAL_DRAW = 2
  DEALER_STOP_DRAW = 17

  TABLE_SIDE_COUNT = 2
  TABLE_HORIZONTAL_PADDING = 1
  TABLE_HORIZONTAL_BORDER = '='
  TABLE_VERTICAL_BORDER = '|'

  HIT_CHOICE = 'hit'
  STAY_CHOICE = 'stay'
  ASKING_TEXT = "Will you #{HIT_CHOICE.upcase} or #{STAY_CHOICE.upcase}?"
  HIT_OR_STAY_CHOICES = [HIT_CHOICE, STAY_CHOICE]

  GENERIC_TIE_TEXT = "It's a TIE!"
  GENERIC_WIN_TEXT = 'You WON!'
  GENERIC_LOSE_TEXT = 'You LOST!'

  attr_reader :deck, :human, :cpu

  def initialize
    @deck = StandardDeck.new
    @human = Gambler.new
    @cpu = Dealer.new
  end

  def play
    intro_sequence

    play_match

    display_goodbye
  end

  private

  def play_match
    draw_initial_cards

    early_blackjack = human.blackjack? || cpu.blackjack?
    players_turn unless early_blackjack

    skip_dealer_turn = early_blackjack || human.bust?
    dealers_turn unless skip_dealer_turn

    display_full_table if skip_dealer_turn
    display_match_result
  end

  def players_turn
    loop do
      display_obscure_table
      return if ask_hit_or_stay == STAY_CHOICE || human.unplayable_hand?
    end

    display_obscure_table
  end

  def dealers_turn
    display_full_table
    until cpu.total >= DEALER_STOP_DRAW
      sleep(0.7)
      cpu << deck.draw
      display_full_table
    end
  end

  def find_hit_or_stay_choice(answer)
    return nil if answer.empty?

    HIT_OR_STAY_CHOICES.find { |choice| choice.start_with? answer }
  end

  def ask_hit_or_stay
    loop do
      answer = CLI.prompt(ASKING_TEXT)
      found_choice = find_hit_or_stay_choice(answer)
      if found_choice
        human << deck.draw if found_choice == HIT_CHOICE
        return found_choice
      end

      CLI.error_message('Invalid choice!')
    end
  end

  def draw_initial_cards
    INITIAL_DRAW.times do
      human << deck.draw
      cpu << deck.draw
    end
  end

  def intro_sequence
    CLI.clear_screen
    display_welcome
    CLI.divide_screen
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def result_message_reason
    if human.total == cpu.total
      "#{GENERIC_TIE_TEXT} You both got the same total!"
    elsif human.blackjack?
      "#{GENERIC_WIN_TEXT} You got Blackjack!"
    elsif cpu.blackjack?
      "#{GENERIC_LOSE_TEXT} The Dealer got Blackjack!"
    elsif human.bust?
      "#{GENERIC_LOSE_TEXT} You went over #{TARGET_SUM}!"
    elsif cpu.bust?
      "#{GENERIC_WIN_TEXT} The Dealer went over #{TARGET_SUM}!"
    elsif human.total > cpu.total
      "#{GENERIC_WIN_TEXT} You were closer to #{TARGET_SUM}!"
    else
      "#{GENERIC_LOSE_TEXT} The Dealer was closer to #{TARGET_SUM}!"
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def display_match_result
    CLI.divide_screen
    puts result_message_reason
    puts ''
  end

  def table_empty_line(length)
    padding = TABLE_HORIZONTAL_PADDING * TABLE_SIDE_COUNT
    full_length = length + padding
    "#{TABLE_VERTICAL_BORDER}#{' ' * full_length}#{TABLE_VERTICAL_BORDER}"
  end

  def table_horizontal_border(length)
    padding = TABLE_HORIZONTAL_PADDING * TABLE_SIDE_COUNT
    full_length = length + TABLE_SIDE_COUNT + padding
    TABLE_HORIZONTAL_BORDER * full_length
  end

  def table_card_hand_line(hand)
    pad = ' ' * TABLE_HORIZONTAL_PADDING
    "#{TABLE_VERTICAL_BORDER}#{pad}#{hand}#{pad}#{TABLE_VERTICAL_BORDER}"
  end

  # rubocop:disable Metrics/MethodLength
  def display_player_hand
    player_hand = human.hand.to_s
    player_hand_length = player_hand.length

    horizontal_border = table_horizontal_border(player_hand_length)
    empty_space = table_empty_line(player_hand_length)
    hand_line = table_card_hand_line(player_hand)

    puts "Your Total: #{human.total}"
    puts horizontal_border
    puts empty_space
    puts hand_line
    puts empty_space
    puts horizontal_border
  end
  # rubocop:enable Metrics/MethodLength

  def display_cpu_hand(obscure: true)
    horizontal_border = '-----------'
    display_total = obscure ? cpu.obscure_total : cpu.total
    display_hand = obscure ? cpu.obscure_hand : cpu.hand

    puts cpu
    puts horizontal_border
    puts "Total: #{display_total}"
    puts display_hand
    puts horizontal_border
    puts ''
  end

  def display_full_table
    CLI.clear_screen
    display_cpu_hand(obscure: false)
    display_player_hand
  end

  def display_obscure_table
    CLI.clear_screen
    display_cpu_hand(obscure: true)
    display_player_hand
  end

  def display_welcome
    puts 'Hello! Welcome to Blackjack!'
    puts ""
  end

  def display_goodbye
    CLI.divide_screen
    puts 'Goodbye! See you next time!'
  end
end

BlackjackGame.new.play
