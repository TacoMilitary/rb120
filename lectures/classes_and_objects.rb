class Person
  attr_accessor :first_name, :last_name

  def initialize(full_name)
    self.name = full_name
  end

  def name=(full_name)
    first_part, last_part = full_name.split
    self.first_name = first_part
    self.last_name = "#{last_part}"
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def to_s
    name
  end

#  def ==(other_person)
#    return false unless other_person.is_a? Person
#
#    name == other_person.name
#  end
end

bob = Person.new 'Robert Smith'

puts "The person's name is: #{bob}"
