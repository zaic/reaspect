require 'polyglot'
require 'treetop'
require_relative 'graph/graph'

#
# parse input
#
$stderr.print "1. Parsing input file... "

Treetop.load 'reaspect'
parser = ReaspectParser.new

res = parser.parse File.read('input.txt')
if res then
    $stderr.puts "OK"
else
    $stderr.puts "FAIL"
    $stderr.puts "Parsing failed on line #{parser.failure_line} column #{parser.failure_column} with reason '#{parser.failure_reason}'"
    exit 1
end

# kind of topsort
$stderr.print "2. Topsorting... "
begin
    graph = ReaspectGraph.new(res.statements)
rescue GraphException => e
    $stderr.puts "FAIL"
    $stderr.puts e.message
    exit 1
end
#p graph.order
$stderr.puts "OK"

$stderr.print "3. Generating C++ program... "


puts '#include <iostream>'
puts 'using std::cout;'
puts 'using std::endl;'
puts
graph.order.each{ |fun| puts graph.functions[fun[0]].generate_header }
puts
puts 'int main() {'
puts

graph.variables.each_value.select{ |var| var.ancestor_function == nil and var.value != nil }.each{ |var| puts var.generate_code }
graph.arrays.each_value{ |arr| puts arr.generate_code }
puts
graph.order.each{ |fun| puts graph.functions[fun[0]].generate_code }

# ToDo generate result output

puts 'return 0;'
puts '}'

$stderr.puts 'OK'
