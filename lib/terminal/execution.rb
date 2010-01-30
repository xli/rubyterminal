
require 'terminal'

Terminal.input($0, ARGV) do |input, output|
  puts "Running in Terminal\n"
  while(File.exists?(input.path)) do
    sleep(0.01)
    if o = output.read
      print o
    end
  end
  exit
end