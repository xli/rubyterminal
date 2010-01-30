
# Terminal arms to prepare a ruby runtime environment for a program to launch new ruby
# process instantly.
# Anytime you got problem of spending too much time on launching ruby process frequently,
# Terminal could be your choice.
#
# Ater Terminal started, it will look for a file called '.terminal.input' in working
# directory as command to execute in a forked new process.
# The output of command execution would be put into another file called '.terminal.output'.
#
# Working Example:
#
# I got problem with spending too much time to wait for rails test process starts. My test
# just need 1 sec to run, but the process need 3 sec to launch. As many time as I run my
# test, as much time as I waste on waiting on launching the process.
#
# Start Terminal with loading environment by specify a ruby file (e.g. test_helper.rb)
#
#   terminal test/test_helper.rb
#
# The directory running Terminal will have a file created called '.terminal.running'
# until it shutdown.
# Add one line code into first line code would be run before your ruby code, e.g. first
# line in test_helper.rb
#
#   require 'terminal/execution'
#
# This code will make sure whether there is Terminal running on the working directory
# or it's parent directory.
# When you run 'ruby test/unit/blabla_test.rb', the code above will create a file named
# '.terminal.input' with command 'test/unit/blabla_test.rb' in the Terminal working directory.
# And start output content reading from '.terminal.input'.
# If it could not find Terminal running, it'll do nothing and let your code run as normal.

# As Terminal, when there is a command coming in, it will:
#
#     Fork a new process
#     Update process ARGV, make the process looks like just launched
#     Output the process's output into '.terminal.output'
#

require 'fileutils'

module Terminal
  VERSION = '0.0.1'

  def start
    FileUtils.touch '.terminal.running'
    yield if block_given?
  ensure
    FileUtils.rm_rf '.terminal.running'
  end

  def process(&block)
    return unless File.exists?('.terminal.input')

    commands = File.open('.terminal.input') do |file|
      file.read
    end.split("\n")

    puts "Processing: #{pretty_command(commands)}"

    fork { do_fork(commands, &block) }
    Process.wait

    puts "Done with exit status: #{$?.exitstatus}"
  ensure
    FileUtils.rm_rf '.terminal.input'
  end

  def do_fork(commands)
    STDOUT.reopen(File.open('.terminal.output', 'w'))
    STDERR.reopen(File.open('.terminal.output', 'w'))
    ARGV.clear
    $0 = commands[0]
    commands[1..-1].each do |arg|
      ARGV << arg.gsub(/\\n/, "\n")
    end
    yield if block_given?
    load($0)
  rescue Exception => e
    $stderr << e.message
    $stderr << e.backtrace.join("\n")
  end

  def running_dir(dir=Dir.pwd)
    return dir if File.exists? File.join(dir, '.terminal.running')
    return nil if dir == File.dirname(dir)

    running_dir(File.dirname(dir))
  end

  def input(progromfile, argv=[])
    return if terminal_process?
    terminal_running_dir = running_dir
    return unless terminal_running_dir
    Dir.chdir(terminal_running_dir) do
      output_file_path = File.expand_path('.terminal.output')
      FileUtils.rm_rf(output_file_path)
      FileUtils.touch(output_file_path)
      input_file_path = File.expand_path('.terminal.input')

      cmd = [progromfile] + argv.collect{|arg| arg.gsub(/\n/, '\\n')}
      input = File.open(input_file_path, 'w') { |file| file << cmd.join("\n") }
      yield(input, File.open(output_file_path)) if block_given?
    end
  end

  def pretty_command(commands)
    commands.collect{|c| c.include?(' ') ? c.inspect : c}.join(' ')
  end

  def terminal_process?
    @terminal_process
  end
  def terminal_process=(value)
    @terminal_process = value
  end

  module_function :start, :process, :running_dir, :input, :pretty_command, :do_fork, :terminal_process?, :terminal_process=

end
