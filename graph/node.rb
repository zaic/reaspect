class GraphNode

    attr_accessor :in, :out
    attr_reader :name

    def initialize(name)
        @in, @out = [], []
        @name = name
    end

end