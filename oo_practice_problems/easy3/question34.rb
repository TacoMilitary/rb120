class AngryCat
  def initialize(age, name, type)
    @age  = age
    @name = name
    @type = type
  end

  def age
    puts @age
  end

  def name
    puts @name
  end

  def hiss
    puts "Hisssss!!!"
  end

  def to_s
    "I am a #{@type} cat"
  end
end

charlie = AngryCat.new 7, 'Charlie', 'russian blue'
unc = AngryCat.new 12, 'Unc', 'tabby'

charlie.age
charlie.name
puts '----'
unc.age
unc.name
puts '----'
puts unc
puts charlie
