class Greeting
  def greet(greeting)
    puts greeting
  end
end

class Hello < Greeting
  def hi
    greet 'Hello'
  end
end

class Goodbye < Greeting
  def bye
    greet 'Goodbye'
  end
end

Greeting.new.greet 'Hello from Greeting specifically'
Hello.new.hi
Goodbye.new.bye
