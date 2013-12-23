class RainbowLoom
  include Bumbleworks::Entity

  process :make_honey
  process :make_molasses, :attribute => :molasses_pid

  attr_accessor :identifier
  attr_accessor :make_honey_process_identifier
  attr_accessor :molasses_pid

  def initialize(identifier)
    @identifier = identifier
  end

  def ==(other)
    other.identifier == identifier
  end

  def update(attributes)
    attributes.each { |k, v| self.send(:"#{k}=", v) }
  end

  def cook_it_up(*foods)
    foods.join(' and ')
  end

  class << self
    def first_by_identifier(identifier)
      return nil unless identifier
      new(identifier)
    end
  end
end