require 'set'
require_relative 'variable'
require_relative 'array'
require_relative 'function'

class GraphException < StandardError

end

class ReaspectGraph

    attr_reader :constants, :variables, :arrays, :functions, :order
    attr_reader :input, :output

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
                    dims = var[:dims].map{ |dim| generate_var_name({ :name => dim }) }
                    # @arrays[var_name] = dims # !!! ToDo !!! push ArrayNode instead of dimensions
                    array_node = ArrayNode.new(var_name, st[:typename], dims)
                    @arrays[var_name] = @variables[var_name] = array_node
                    dims.reduce(:*).times do |id|
                        cid = id
                        var_name_with_id = dims.reverse.map { |i| res, cid = cid % i, cid / i; res }.reverse.reduce(var_name) { |str, cur| str += '[' + cur.to_s + ']' }
                        @variables[var_name_with_id] = element_node = ArrayElementNode.new(var_name_with_id, st[:typename], array_node)
                        array_node.elements << element_node
                    end
                else
                    @variables[var_name] = VariableNode.new(var_name, st[:typename])
                end
            end
        end
    end

    def add_scalar_function(st)
        # ToDo refactor
        # ToDo function cost can be expression
        node = FunctionNode.new(st[:name], st[:code_name] ? st[:code_name] : st[:name], st[:cost].to_i)
        st[:arguments].each do |arg|
            arg_node = @variables[generate_var_name(arg)]
            raise GraphException.new "Unknown variable '#{arg}' in function '#{st[:name]}' arguments." unless arg_node
            node.in << arg_node
            arg_node.out << node
        end
        st[:result].each do |res|
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
        # p "generate var name, arg = " + arg.to_s
        name = arg[:name]
        if @arrays.has_key?(name) then
            # p "i'm is array"
            return name + arg[:dims].map{ |var| '[' + eval_index(var, counters).to_s + ']' }.join
        elsif @variables.has_key?(name) then
            # p "i'm is variable"
            return name
        else
            # p "i'm is index oO"
            return eval_index(name, counters)
        end
    end

    def add_mass_function(st)
        # p "add mass function" + st.to_s
        generate_index_values(st[:mass]).each do |counters|
            # puts "counters = " + counters.to_s
            cur_st = { :statement => :function,
                       :name      => st[:name] + '_' + counters.each_value.map { |val| val.to_s }.join('_') ,
                       :code_name => st[:name],
                       :cost      => st[:cost],
                       :arguments => st[:arguments].map{ |arg| { :name => generate_var_name(arg, counters), :dims => [] } },
                       :result    => st[:result].map { |arg| { :name => generate_var_name(arg, counters), :dims => [] } } }
            add_scalar_function(cur_st)
        end
        # p "end mass function"
    end

    def fill_functions(statements)
        statements.select{ |st| st[:statement] == :function }.each do |st|
            st[:mass].size == 0 ? add_scalar_function(st) : add_mass_function(st)
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
        dfs_queue = []
        @input.each{ |var| var.distance = 0; dfs_queue << var }
        while node = dfs_queue.select{ |t| t.visited != :dfs }.min
            $stderr.puts "dfs from " + node.name + ' with distance = ' + node.distance.to_s
            dfs_queue += node.dfs.flatten
        end

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
        # p @variables
        fill_functions(parser_result)
        # @functions.each_key { |key| p "function " + key + ": " + @functions[key].to_s }
        fill_inout(parser_result)

        @order = []
        top_sort
    end

end
