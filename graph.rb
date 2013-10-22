class Node

    attr_accessor :in, :out
    attr_reader :name

    def initialize(name)
        @in, @out = [], []
        @name = name
    end

end

class VariableNode < Node

    attr_accessor :visited
    attr_reader :ancestor_function, :type

    def initialize(name, type)
        super(name)
        @type = type
    end

    def dfs
        return if @visited
        @visited = :dfs
        @out.each{ |node| node.dfs }
    end

    def top_sort
        return if @visited == :top_sort
        @visited = :top_sort
        @ancestor_function = @in.detect { |fun| [:dfs, :top_sort].include?(fun.visited) }
        @ancestor_function.top_sort
    end
    
end

class FunctionNode < Node

    attr_reader :visited

    def initialize(name)
        super(name)
        @visited = 0
    end

    def execute?
        @exec
    end
    
    def dfs
        @visited += 1
        return if @visited != @in.size
        @visited = :dfs
        @out.each{ |var| var.dfs }
    end

    def top_sort
        return if @visited == :top_sort
        @visited = :top_sort
        @in.each { |var| var.top_sort }
    end

end

class ReaspectGraph

    attr_reader :variables, :functions, :order

    def fill_variables(statements)
        statements.select{ |st| st[:statement] == :variable }.each do |st|
            st[:variable].each do |var_name| 
                @variables[var_name] = VariableNode.new(var_name, st[:typename])
            end
        end
    end

    def fill_functions(statements)
        statements.select{ |st| st[:statement] == :function }.each do |st|
            node = FunctionNode.new(st[:name])
            st[:arguments].each do |arg|
                arg_node = @variables[arg]
                # ToDo throw exception if arg_node is nil
                node.in << arg_node
                arg_node.out << node
            end
            st[:result].each do |res|
                res_node = @variables[res]
                # ToDo throw one more exception
                node.out << res_node
                res_node.in << node
            end
            @functions[st[:name]] = node
        end
    end

    def fill_inout(statements)
        statements.each do |st|
            case st[:statement]
                when :input then
                    st[:variables].each{ |var| @input << @variables[var[:name]] }
                when :output then 
                    st[:variables].each{ |var| @output << @variables[var] }
            end
        end
    end

    def top_sort
        @input.each{ |var| var.dfs }
        @input.each{ |var| var.visited = :top_sort }
        @output.each{ |var| var.top_sort }
    end

    def initialize(parser_result)
        @variables = {}
        @functions = {}
        @input, @output = [], []
        fill_variables(parser_result)
        fill_functions(parser_result)
        fill_inout(parser_result)
        top_sort
    end

end
