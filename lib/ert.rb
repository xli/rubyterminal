
begin
  require 'ruby_terminal'
rescue LoadError
  require 'rubygems'
  require 'ruby_terminal'
end

RubyTerminal.execute($0, ARGV, STDOUT) do
  exit
end
