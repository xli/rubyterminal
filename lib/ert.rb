
begin
  require 'ruby_terminal'
rescue LoadError
  require 'rubygems'
  require 'ruby_terminal'
end

if defined?(RAILS_ROOT)
  require 'ruby_terminal/rails_project_environment'
  RubyTerminal::RailsProjectEnvironment.reload
end

RubyTerminal.execute($0, ARGV, STDOUT) do
  exit
end
