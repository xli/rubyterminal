require 'fileutils'
require 'ruby_terminal/terminal_input'
require 'ruby_terminal/terminal_output'

module RubyTerminal
  module Execution

    # The ruby execution script may require 'ert' for execution, use 'ignore_execution_request' status
    # marker to git rid of 'ert' script control.
    def ignore_execution_request?
      @ignore_execution_request
    end

    def ignore_execution_request=(value)
      @ignore_execution_request = value
    end

    # Load environment files for Terminal base process
    # This method take care of git rid of 'ert' script control inside the environment script
    def load_environment(env_files)
      self.ignore_execution_request = true

      if env_files.nil? || env_files.empty?
        puts "Warning: are you sure you don't need to load any ruby script to initialize environment?"
        puts "Usage: rt <ruby_environment_script>"
        puts "Option: --rails_test        set ENV[\"RAILS_ENV\"] = \"test\" and load config/environment"
        puts "                            must run in root directory of Rails project"
      else
        start_at = Time.now
        env_files.each do |env_file|
          if env_file == '--rails_test'
            env_file = File.expand_path("config/environment.rb")

            raise "Could not find #{env_file.inspect}. You must start RubyTerminal in the root directory of rails project when you use '--rails' option" unless File.exists?(env_file)
            ENV["RAILS_ENV"] = "test"
          end

          puts "require #{File.expand_path(env_file).inspect}"
          require File.expand_path(env_file)
        end
        puts "Environment loaded in #{Time.now - start_at} seconds"
      end
    end

    # When 'ert' script is loaded, this method would detect RubyTerminal runtime and
    # take over execution control when it found RubyTerminal runtime
    # Should give a block to control what's next to do after execution finished inside
    # RubyTerminal runtime.
    def execute(progromfile, argv=[], logger=[])
      input(progromfile, argv) do |input, output|
        logger << "Running in RubyTerminal (#{running_dir})\n"
        output.output_until_execution_finished(input, STDOUT)
        yield if block_given? # for command to execute 'exit'
      end
    end

    # detect RubyTerminal runtime launching directory
    def running_dir(dir=Dir.pwd)
      return dir if File.exists? File.join(dir, '.terminal.running')
      return nil if dir == File.dirname(dir)

      running_dir(File.dirname(dir))
    end

    def input(progromfile, argv=[])
      return if self.ignore_execution_request?
      return unless running_dir

      progromfile = File.expand_path(progromfile)
      Dir.chdir(running_dir) do
        TerminalOutput.renew do |output|
          input = TerminalInput.write(progromfile, argv)
          yield(input, output) if block_given?
        end
      end
    end

  end
end
