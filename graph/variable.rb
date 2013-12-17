require_relative 'node'

class VariableNode < GraphNode

    attr_reader :ancestor_function, :type
    attr_accessor :value

    def initialize(name, type)
        super(name)
        @type = type
    end

    def dfs
        return if @visited == :dfs
        @visited = :dfs
        @out.each{ |node| node.distance = [node.distance, @distance].min }
        @out.select{ |node| node.can_dfs? }
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        @ancestor_function = @in.select{ |fun| [:dfs, :top_sort].include?(fun.visited) }.min
        raise GraphException.new "Variable '#{name}'' can't be calculated." if @ancestor_function == nil
        @ancestor_function.top_sort(order)
    end

    def code_name
        @ancestor_function ? @name + '_' + @ancestor_function.code_name : @name
    end

    # Variable initialization:
    #   char symbol = 'e';
    def generate_code
        # return if not @type # ToDo: remove?
        @type.to_s + ' ' + code_name + ' = ' + value.to_s + ';'
    end

    # Variable definition:
    #   char symbol;
    def generate_definition
        # return if not @type # ToDo: remove?
        @type.to_s + ' ' + code_name + ";\n"
    end

    # Variable as function argument:
    #   f(const double& width);
    def generate_argument_code
        'const ' + @type.to_s + '& ' + code_name
    end

    # Variable as function result:
    #   f(int& square);
    def generate_result_code
        @type.to_s + '& ' + code_name
    end

    def generate_output
        '    cout << ' + '"' + name + '" ' + ' << " = " << ' + code_name + ' << endl;'
    end

end
