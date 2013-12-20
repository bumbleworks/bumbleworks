class Furby
  include Bumbleworks::Entity

  process :make_honey

  attr_reader :identifier
  attr_accessor :make_honey_process_identifier

  def initialize(identifier)
    @identifier = identifier
  end

  def ==(other)
    other.identifier == identifier
  end

  def update(attributes)
    attributes.each { |k, v| self.send(:"#{k}=", v) }
  end

  class << self
    def first_by_identifier(identifier)
      new(identifier)
    end
  end
end