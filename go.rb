require 'polyglot'
require 'treetop'
require_relative 'graph.rb'

# parse input
Treetop.load 'reaspect'
parser = ReaspectParser.new

res = parser.parse File.read('input.txt')
if res then
#p res.statements
else
    puts parser.failure_reason
    puts parser.failure_line
    puts parser.failure_column
    exit(1)
end

# kind of topsort
graph = ReaspectGraph.new(res.statements)
#p graph.order

graph.order.each{ |fun| puts graph.functions[fun[0]].generate_header }
puts
puts "int main() {"
puts

graph.variables.each_value.select{ |var| var.ancestor_function == nil }.select{ |var| var.value != nil }.each{ |var| puts var.generate_code }
puts
graph.order.each{ |fun| puts graph.functions[fun[0]].generate_code }

puts "return 0;"
puts "}"

