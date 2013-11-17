class GraphNode

    attr_accessor :in, :out
    attr_reader :name

    def initialize(name)
        @in, @out = [], []
        @name = name
    end

end

class GraphException < StandardError

end

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
        @type.to_s + " " + code_name + " = " + value.to_s + ";"
    end

end

class FunctionNode < GraphNode

    attr_reader :visited

    def initialize(name)
        super(name)
        @visited = 0
    end

    def execute?
        @visited == :top_sort
    end
    
    def dfs
        @visited += 1
        return if @visited != @in.size
        @visited = :dfs
        @out.each{ |var| var.dfs }
    end

    def top_sort(order)
        return if @visited == :top_sort
        @visited = :top_sort
        dependencies = @in.map do |var| 
            var.top_sort(order)
            var.ancestor_function
        end.select{ |fun| fun }.sort.uniq.map{ |fun| fun.name } # ToDo refactor
        order << [name, dependencies];
    end

    def generate_code
        var_def = @out.map{ |var| var.type.to_s + " " + var.name + "_" + @name + ";" }.join("\n")
        arg_def = @in.map{ |var| var.code_name + ", "}.join +
            @out.map{ |var| var.name + "_" + @name}.join(", ");
#arg_def = @in.map{ |var| "const " + var.type.to_s + "& " + var.code_name + ", "}.join + @out.map{ |var| var.type.to_s + "& " + var.name + "_" + @name}.join(", ");
        var_def + "\n" + name + "(" + arg_def + ");\n\n"
    end

    def generate_header
        arg_def = @in.map{ |var| "const " + var.type.to_s + "& " + var.code_name + ", "}.join + 
            @out.map{ |var| var.type.to_s + "& " + var.name + "_" + @name}.join(", ");
        "void " + name + " (" + arg_def + ");\n"
    end

end

class ReaspectGraph

    attr_reader :constants, :variables, :functions, :order

    def fill_constants(statement)
        # ToDo check for redefinition
        statement.select{ |st| st[:statement] == :const }.each do |st|
            st[:variables].each do |var|
                @constants[var[:name]] = var[:value]
            end
        end
    end

    def fill_variables(statements)
        # ToDo check for redefinition
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
                raise GraphException.new "Unkonwn varialbe '#{arg}' in function '#{st[:name]}' arguments." unless arg_node
                node.in << arg_node
                arg_node.out << node
            end
            st[:result].each do |res|
                res_node = @variables[res]
                raise GraphException.new "Unkonwn varialbe '#{res}' in function '#{st[:name]}' result." unless res_node
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
                    st[:variables].each do |var| 
                        variable = @variables[var[:name]] 
                        raise GraphException.new "Unkonwn input variable '#{var[:name]}'" unless variable
                        @input << variable
                        variable.value = var[:value]
                    end
                when :output then 
                    st[:variables].each do |var| 
                        variable = @variables[var] 
                        raise GraphException.new "Unkonwn output variable '#{var}'" unless variable
                        @output << variable
                    end
            end
        end
    end

    def top_sort
        @input.each{ |var| var.dfs }
        @input.each{ |var| var.visited = :top_sort }
        @output.each{ |var| var.top_sort(@order) }
    end

    def initialize(parser_result)
        @variables = {}
        @functions = {}
        @input, @output = [], []
        @constants = {}

        fill_constants(parser_result)
        fill_variables(parser_result)
        fill_functions(parser_result)
        fill_inout(parser_result)

        @order = []
        top_sort
    end

end
