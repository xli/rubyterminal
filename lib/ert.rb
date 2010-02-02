
begin
  require 'ruby_terminal'
rescue LoadError
  require 'rubygems'
  require 'ruby_terminal'
end

RubyTerminal.execute($0, ARGV, STDOUT) do
  exit! # we don't want any other at_exit block happens like Test::Unit does
end
