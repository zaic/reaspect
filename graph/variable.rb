require_relative 'node'

class VariableNode < GraphNode

    attr_accessor :visited
    attr_reader :ancestor_function, :type
    attr_accessor :value

    def initialize(name, type)
        super(name)
        @type = type
    end

    def dfs
        return if @visited
        @visited = :dfs
        @out.each{ |node| node.dfs }
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        @ancestor_function = @in.detect { |fun| [:dfs, :top_sort].include?(fun.visited) }
        @ancestor_function.top_sort(order)
    end

    def code_name
        @ancestor_function ? @name + "_" + @ancestor_function.name : @name
    end

    def generate_code
        return if not @type
        @type.to_s + " " + code_name + " = " + value.to_s + ";"
    end

end