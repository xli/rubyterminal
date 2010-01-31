require 'fileutils'
require 'ruby_terminal/terminal_input'

module RubyTerminal
  module Execution

    def ignore_execution_request?
      @ignore_execution_request
    end

    def ignore_execution_request=(value)
      @ignore_execution_request = value
    end

    def load_environment(env_files)
      self.ignore_execution_request = true

      if env_files.nil? || env_files.empty?
        puts "Warning: are you sure you don't need to load any ruby script to initialize environment?"
        puts "Usage: rt <ruby_environment_script>"
      else
        env_files.each do |env_file|
          puts "require #{File.expand_path(env_file).inspect}"
          require File.expand_path(env_file)
        end
        puts "Environment loaded"
      end
    end

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
        output_file_path = File.expand_path('.terminal.output')
        FileUtils.rm_rf(output_file_path)
        FileUtils.touch(output_file_path)

        File.open(output_file_path) do |output|
          input = TerminalInput.write(progromfile, argv)
          yield(input, output) if block_given?
        end
      end
    end

    def execute(progromfile, argv, logger=[])
      input(progromfile, argv) do |input, output|
        logger << "Running in RubyTerminal(#{running_dir})\n"
        while(File.exists?(input.path)) do
          sleep(0.01)
          if o = output.read
            print o
          end
        end
        yield if block_given?
      end
    end

  end
end
