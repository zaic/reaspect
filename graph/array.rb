require_relative 'node'

class ArrayNode < GraphNode

    # attr_accessor :visited
    attr_reader :ancestor_function, :type
    # attr_accessor :value

    def initialize(name, type, elements)
        super(name)
        @type = type
        @elements = elements
    end

    def dfs
        return if @visited
        @visited = :dfs
        @elements.each{ |element| element.dfs }
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        @elements.each { |element| element.top_sort(order) }
    end

    def code_name
        @ancestor_function ? @name + "_" + @ancestor_function.name : @name
    end

end