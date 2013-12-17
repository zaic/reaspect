require_relative 'node'

class FunctionNode < GraphNode

    attr_reader :code_name, :resolve

    def initialize(name, code_name, cost)
        super(name)
        @code_name = code_name
        @cost = cost
        @visited = 0
        @resolve = []
    end

    def execute?
        @visited == :top_sort
    end

    def distance
        @in.reduce(0){ |res, node| res + node.distance } + @cost
    end

    def can_dfs?
        @in.reduce(true){ |res, node| res and node.visited == :dfs }
    end

    def dfs
        @visited += 1
        return if @visited != @in.size
        @visited = :dfs

        # $stderr.puts 'Function ' + name + ' has distance ' + @distance.to_s
        @out.each{ |node| node.distance = [node.distance, distance].min }
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
        "    scheduler.registerTask(new #{name}());\n"
    end

    def generate_header
        # arg_def = @in.map{ |var| 'const ' + var.type.to_s + '& ' + var.code_name + ', '}.join +
        #    @out.map{ |var| var.type.to_s + '& ' + var.name + '_' + @code_name}.join(', ');
        arg_def = @in.map { |var| var.generate_argument_code + ', ' }.join +
                  @out.map{ |var| var.generate_result_code }.join(', ');
        'void ' + @code_name + ' (' + arg_def + ");\n"
    end

    def check_deps
        @in.each{ |var| var.ancestor_function.resolve << name if var.ancestor_function }
    end

    def generate_class
        var_def = @out.map{ |var| var.generate_definition }.join
        arg_def = @in.map { |var| var.code_name }.join(', ') + ',   ' +
            @out.map{ |var| var.code_name }.join(', ');
        dep_def = resolve.map{ |s| '"' + s + '"'}.join(', ')

        var_def +
            "struct #{name} : public Reaspect::Task {\n\n" +
            "    #{name}() : Task(\"#{name}\", #{@in.size}, vector<string>{#{dep_def}}) { }\n\n" +
            "    virtual void go() {\n" +
            "        " + @code_name + '(' + arg_def + "); \n" +
            "    }\n};\n\n"
    end

end