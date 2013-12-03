require_relative 'node'

class ArrayNode < GraphNode

    # attr_accessor :visited
    attr_reader :ancestor_function, :type
    # attr_accessor :value

    def initialize(name, type)
        super(name)
        @type = type
        @elements = []
    end

    def dfs
        return if @visited == :dfs
        @visited = :dfs
        @elements.each{ |element| element.dfs }
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        @elements.each { |element| element.top_sort(order) }
    end

    def code_name
        @name
    end

    def ancestor_function
        @elements.reduce([]){ |element, res| res << element.ancestor_function }.flatten
    end

end

class ArrayElementNode < VariableNode

    def initialize(name, type)
        super(name, type)
    end

    def code_name
        @name
    end

    def generate_definition
        ''
    end

end