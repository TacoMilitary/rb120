module Speed
  def go_fast
    puts "I am a #{self.class} and going super fast!"
  end
end

class Car
  include Speed

  def go_slow
    puts "I am safe and driving slow."
  end
end

class Truck
  include Speed

  def go_very_slow
    puts "I am a heavy truck and like going very slow."
  end
end

puts Car.instance_methods.include? :go_fast
puts Truck.instance_methods.include? :go_fast
Truck.new.go_fast
Car.new.go_fast
