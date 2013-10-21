require 'polyglot'
require 'treetop'

Treetop.load 'reaspect'
parser = ReaspectParser.new

res = parser.parse File.read('input.txt')
if res then
    p res.statements
else
    puts parser.failure_reason
    puts parser.failure_line
    puts parser.failure_column
end
