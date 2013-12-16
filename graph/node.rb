class GraphNode

    attr_accessor :in, :out
    attr_reader :name
    attr_accessor :distance
    attr_accessor :visited

    def initialize(name)
        @in, @out = [], []
        @name     = name
        @distance = Float::INFINITY
        @visited  = nil
    end

    def can_dfs?
        true
    end

    def <=>(other)
        # $stderr.puts '<=>: ' + @name + ' ' + distance.to_s + ' : ' + other.name + ' ' + other.distance.to_s
        return distance <=> other.distance if distance != other.distance
        return @name <=> other.name if @name != other.name
        return 0
    end

end