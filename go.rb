require 'polyglot'
require 'treetop'
require_relative 'graph/graph'

if ARGV.size != 1
    $stderr.puts "Usage: #{$PROGRAM_NAME} input_file"
    exit 1
end
input_file = ARGV[0].to_s

#
# parse input
#
$stderr.print "1. Parsing input file... "

Treetop.load 'reaspect'
parser = ReaspectParser.new

res = parser.parse File.read(input_file)
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

$stderr.puts "OK"

$stderr.print "3. Generating C++ program... "


puts '#include <iostream>'
puts 'using std::cout;'
puts 'using std::endl;'
puts
graph.order.map{ |fun| graph.functions[fun[0]] }.sort_by{ |fun| fun.code_name }.uniq{ |fun| fun.code_name }.each{ |fun| puts fun.generate_header }
puts
puts 'int main() {'
puts

graph.variables.each_value.select{ |var| var.ancestor_function == nil and var.value != nil }.each{ |var| puts var.generate_code }
graph.arrays.each_value{ |arr| puts arr.generate_code }
puts
graph.order.each{ |fun| puts graph.functions[fun[0]].generate_code }

graph.output.each { |var| puts var.generate_output }

puts 'return 0;'
puts '}'

$stderr.puts 'OK'
