class Quadruped
  def run
    'running!'
  end

  def jump
    'jumping!'
  end
end

class Dog < Quadruped
  def speak
    'bark!'
  end

  def swim
    'swimming!'
  end

  def fetch
    'fetching!'
  end
end

class Cat < Quadruped
  def speak
    'meow!'
  end
end

class Bulldog < Dog
  def swim
    "can't swim!"
  end
end

teddy = Dog.new
puts teddy.speak
puts teddy.swim

bully = Bulldog.new
puts bully.swim

# Quadruped
# Cat -- Dog
#        Bulldog
