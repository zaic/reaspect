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
        return if not @type
        @type.to_s + " " + code_name + " = " + value.to_s + ";"
    end

end

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

class FunctionNode < GraphNode

    attr_reader :visited

    def initialize(name, code_name)
        super(name)
        @code_name = code_name
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
        end.flatten.select{ |fun| fun }.map{ |fun| fun.name }.sort.uniq # ToDo refactor
        order << [name, dependencies];
    end

    def generate_code
        var_def = @out.map{ |var| var.type.to_s + " " + var.name + "_" + @code_name + ";" }.join("\n")
        arg_def = @in.map{ |var| var.code_name + ", "}.join +
            @out.map{ |var| var.name + "_" + @code_name}.join(", ");
#arg_def = @in.map{ |var| "const " + var.type.to_s + "& " + var.code_name + ", "}.join + @out.map{ |var| var.type.to_s + "& " + var.name + "_" + @name}.join(", ");
        var_def + "\n" + name + "(" + arg_def + ");\n\n" # ToDo name -> @code_name ?
    end

    def generate_header
        arg_def = @in.map{ |var| "const " + var.type.to_s + "& " + var.code_name + ", "}.join + 
            @out.map{ |var| var.type.to_s + "& " + var.name + "_" + @code_name}.join(", ");
        "void " + name + " (" + arg_def + ");\n"
    end

end

class ReaspectGraph

    attr_reader :constants, :variables, :arrays, :functions, :order

    def eval_index(expression, counters = {})
        expression = (counters.merge(@constants)).reduce('') { |str, cur| str +=  "#{cur[0]} = #{cur[1]}; " } + expression
        # p expression
        eval(expression)
    end

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
            st[:variable].each do |var|
                var_name = var[:name]
                if var[:dims].size > 0 then
                    dims = var[:dims].map(&:to_i) # ToDo: use eval
                    @arrays[var_name] = dims
                    dims.reduce(:*).times do |id|
                        cid = id
                        var_name_with_id = dims.reverse.map { |i| res, cid = cid % i, cid / i; res }.reverse.reduce(var_name) { |str, cur| str += '[' + cur.to_s + ']' }
                        @variables[var_name_with_id] = VariableNode.new(var_name_with_id, nil)
                    end
                else
                    @variables[var_name] = VariableNode.new(var_name, st[:typename])
                end
            end
        end
    end

    def add_scalar_function(st)
        node = FunctionNode.new(st[:name], st[:code_name] ? st[:code_name] : st[:name]) # ToDo refactor
        st[:arguments].each do |arg|
            # arg_node = generate_var_name(@variables[arg[:name]])
            arg_node = @variables[generate_var_name(arg)]
            raise GraphException.new "Unknown variable '#{arg}' in function '#{st[:name]}' arguments." unless arg_node
            node.in << arg_node
            arg_node.out << node
        end
        st[:result].each do |res|
            # res_node = generate_var_name(@variables[res[:name]])
            res_node = @variables[generate_var_name(res)]
            raise GraphException.new "Unknown variable '#{res}' in function '#{st[:name]}' result." unless res_node
            node.out << res_node
            res_node.in << node
        end
        @functions[st[:name]] = node
    end

    def generate_index_values(dims, counters = {})
        return [counters.clone] if dims.empty?

        name = dims.first[:counter]
        lower_bound = eval_index(dims.first[:bound_from], counters).to_i
        upper_bound = eval_index(dims.first[:bound_to], counters).to_i
        result = []
        (lower_bound...upper_bound).each do |i|
            counters[name] = i
            result << generate_index_values(dims[1..-1], counters)
        end
        result.flatten
    end

    def generate_var_name(arg, counters = {})
         p "generate var name, arg = " + arg.to_s
        name = arg[:name]
        if @variables.has_key?(name) then
            # p "i'm is variable"
            return name
        elsif @arrays.has_key?(name) then
            # p "i'm is array"
            return name + arg[:dims].map{ |var| '[' + eval_index(var, counters).to_s + ']' }.join
        else
            # p "i'm is index oO"
            return eval_index(name, counters)
        end
    end

    def add_mass_function(st)
         p "add mass function" + st.to_s
        generate_index_values(st[:mass]).each do |counters|
             puts "counters = " + counters.to_s
            cur_st = { :statement => :function,
                       :name      => st[:name] + '_' + counters.each_value.map { |val| val.to_s }.join('_') ,
                       :code_name => st[:name],
                       :arguments => [],
                       :result    => [] }
            # ToDo refactor to map
            st[:arguments].each { |arg| cur_st[:arguments] << { :name => generate_var_name(arg, counters) } }
            st[:result].each { |arg| cur_st[:result] << { :name => generate_var_name(arg, counters) } }
            add_scalar_function(cur_st)
        end
         p "end mass function"
    end

    def fill_functions(statements)
        statements.select{ |st| st[:statement] == :function }.each do |st|
            if st[:mass].size == 0
                add_scalar_function(st)
            else
                add_mass_function(st)
            end
        end
    end

    def fill_inout(statements)
        statements.each do |st|
            case st[:statement]
                when :input then
                    st[:variables].each do |var| 
                        variable = @variables[var[:name]] 
                        raise GraphException.new "Unknown input variable '#{var[:name]}'" unless variable
                        @input << variable
                        variable.value = var[:value]
                    end
                when :output then 
                    st[:variables].each do |var| 
                        variable = @variables[var[:name]]
                        raise GraphException.new "Unknown output variable '#{var}'" unless variable
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
        @arrays, @variables = {}, {}
        @functions = {}
        @input, @output = [], []
        @constants = {}

        fill_constants(parser_result)
        fill_variables(parser_result)
        p @variables
        fill_functions(parser_result)
        @functions.each_key { |key| p "function " + key + ": " + @functions[key].to_s }
        fill_inout(parser_result)

        @order = []
        top_sort
    end

end
