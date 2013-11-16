require 'polyglot'
require 'treetop'
require_relative 'graph.rb'

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

graph.order.each{ |fun| puts graph.functions[fun[0]].generate_header }
puts
puts "int main() {"
puts

graph.variables.each_value.select{ |var| var.ancestor_function == nil }.select{ |var| var.value != nil }.each{ |var| puts var.generate_code }
puts
graph.order.each{ |fun| puts graph.functions[fun[0]].generate_code }

puts "return 0;"
puts "}"

$stderr.puts "OK"
