require "ruote"
require "ruote/reader"

module Bumbleworks
  class TreeBuilder
    class InvalidTree < StandardError; end

    attr_reader :tree, :name

    def initialize(options)
      @forced_name = options[:name]
      @definition = options[:definition]
      @tree = options[:tree]
      unless !!@definition ^ !!@tree
        raise ArgumentError, "Must specify either definition or tree (not both)" 
      end
    end

    def build!
      initialize_tree_from_definition! unless @tree
      if @name = name_from_tree
        @forced_name ||= name
        raise InvalidTree, "Name does not match name in definition" if @forced_name != @name
        @tree[1].delete(@tree[1].keys.first)
      end
      @name = @forced_name
      add_name_to_tree!
      @tree
    rescue ::Ruote::Reader::Error => e
      raise InvalidTree, e.message
    end

    class << self
      def from_definition(*args, &block)
        tree = ::Ruote.define *args, &block
        builder = new(:tree => tree)
      end
    end

  private

    def initialize_tree_from_definition!
      converted = @definition.strip.gsub(/^Bumbleworks.define_process/, 'Ruote.define')
      @tree = ::Ruote::Reader.read(converted)
    end

    def name_from_tree
      first_key, first_value = @tree[1].first
      name_from_tree = if first_key == 'name'
        first_value
      elsif first_value.nil?
        first_key
      end
    end

    def add_name_to_tree!
      @tree[1] = { "name" => @name }.merge(@tree[1])
    end
  end
end