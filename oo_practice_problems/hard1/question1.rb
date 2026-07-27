module Moveable
  attr_accessor :speed, :heading
  attr_writer :fuel_capacity, :fuel_efficiency

  def range
    @fuel_capacity * @fuel_efficiency
  end
end

class Boat
  include Moveable

  attr_reader :propeller_count, :hull_count

  def initialize(num_propellers, num_hulls, km_traveled_per_liter, liters_of_fuel_capacity)
    # ... code omitted ...
  end

  def range
    super + 10
  end
end

class WheeledVehicle
  include Moveable

  attr_accessor :speed, :heading

  def initialize(tires_array, km_travelled_per_liter, liters_of_fuel_capacity)
    @tires = tires_array
    self.fuel_efficiency = km_travelled_per_liter
    self.fuel_capacity = liters_of_fuel_capacity
  end

  def tire_pressure(tire_index)
    @tires[tire_index]
  end

  def inflate_tire(tire_index, pressure)
    @tires[tire_index] = pressure
  end
end

class Auto < WheeledVehicle
  def initialize
    super([30,30,32,32], 50, 25.0)
  end
end

class Motorcycle < WheeledVehicle
  def initialize
    super([20,20], 80, 8.0)
  end
end

class Motorboat < Boat
end

class Catamaran < Boat
end

p Auto.new.range
