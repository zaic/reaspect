require_relative 'node'

class ArrayNode < VariableNode

    # attr_accessor :visited
    attr_reader :elements, :dims
    # attr_accessor

    def initialize(name, type, dims)
        super(name, type)
        @dims = dims
        @elements = []
        @child_counter = dims.reduce(:*)
    end

    def dfs
        return if @visited == :dfs
        @visited = :dfs
        @out.each{ |var| var.dfs }
        @elements.each{ |element| element.dfs }
    end

    def child_dfs
        @child_counter -= 1
        dfs if @child_counter == 0
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort

        @ancestor_function = @in.detect { |fun| [:dfs, :top_sort].include?(fun.visited) }
        if @ancestor_function
            @ancestor_function.top_sort(order)
        else
            @elements.each { |element| element.top_sort(order) }
            @ancestor_function = @elements.map{ |element| element.ancestor_function }
        end
    end

    def code_name
        @name
    end

    # Code generation

    # Variable initialization or definition:
    #   char string[256]
    def generate_code
        @type.to_s + ' ' + code_name + @dims.map{ |i| '[' + i.to_s + ']'}.join + ';'
    end

    def generate_definition
        ''
    end

    # Variable as function argument:
    #   f(int data[8]);
    def generate_argument_code
        @type.to_s + ' ' + code_name + @dims.map{ |i| '[' + i.to_s + ']'}.join
    end

    # Variable as function result:
    #   f(double complex[2]);
    def generate_result_code
        generate_argument_code
    end

end

class ArrayElementNode < VariableNode

    def initialize(name, type, parent_array)
        super(name, type)
        @parent_array = parent_array
    end

    def dfs
        return if @visited == :dfs
        super
        @parent_array.child_dfs
    end

    def code_name
        @name
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        @ancestor_function = @in.detect { |fun| [:dfs, :top_sort].include?(fun.visited) }
        if @ancestor_function
            @ancestor_function.top_sort(order)
        else
            @parent_array.top_sort(order)
            @ancestor_function = @parent_array.ancestor_function
        end
    end

    def generate_definition
        ''
    end

    def generate_argument_code
        'const ' + @type.to_s + '& '
    end

    def generate_result_code
        @type.to_s + '& '
    end

end