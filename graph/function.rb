require_relative 'node'

class FunctionNode < GraphNode

    attr_reader :code_name

    def initialize(name, code_name, cost)
        super(name)
        @code_name = code_name
        @cost = cost
        @visited = 0
    end

    def execute?
        @visited == :top_sort
    end

    def distance
        @in.reduce(0){ |res, node| res + node.distance }
    end

    def can_dfs?
        @in.reduce(true){ |res, node| res and node.visited == :dfs }
    end

    def dfs
        @visited += 1
        return if @visited != @in.size
        @visited = :dfs

        @distance += @cost
        @out.each{ |node| node.distance = [node.distance, @distance].min }
        @out.clone
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        dependencies = @in.map do |var|
            var.top_sort(order)
            var.ancestor_function
        end.flatten.select{ |fun| fun }.map{ |fun| fun.name }.sort.uniq # ToDo refactor
        order << [name, dependencies];
    end

    def generate_code
        var_def = @out.map{ |var| var.generate_definition }.join
        arg_def = @in.map { |var| var.code_name }.join(', ') + ',   ' +
                  @out.map{ |var| var.code_name }.join(', ');
        var_def + @code_name + '(' + arg_def + ");\n\n"
    end

    def generate_header
        # arg_def = @in.map{ |var| 'const ' + var.type.to_s + '& ' + var.code_name + ', '}.join +
        #    @out.map{ |var| var.type.to_s + '& ' + var.name + '_' + @code_name}.join(', ');
        arg_def = @in.map { |var| var.generate_argument_code + ', ' }.join +
                  @out.map{ |var| var.generate_result_code }.join(', ');
        'void ' + @code_name + ' (' + arg_def + ");\n"
    end

end