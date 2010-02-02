require 'fileutils'
require 'ruby_terminal/terminal_input'

module RubyTerminal
  module Terminal

    # A terminal is started from here.
    # Start method takes care of terminal running status marker
    # and ignores SignalException for clean output
    def start
      alias $__0 $0
      FileUtils.touch '.terminal.running'
      yield if block_given?
    rescue SignalException
      # ignore
    ensure
      ARGV.clear
      alias $0 $__0
      FileUtils.rm_rf '.terminal.running'
    end

    def loop_process(logger)
      logger << ">> "
      logger.flush
      loop do
        if process(logger)
          logger << ">> "
          logger.flush
        end
        sleep(0.1)
      end
    end

    def process(logger=[])
      TerminalInput.get do |input|
        programfile, argv = input.read
        logger << pretty_command(programfile, argv) << "\n"

        pid = fork do
          do_fork(programfile, argv)
        end
        thread = Thread.start do
          begin
            TerminalOutput.open_for_read do |output|
              output.output_until_execution_finished(input, logger)
            end
          ensure
            Process.kill 'TERM', pid
          end
        end
        Process.wait
        Thread.kill thread

        logger << "=> exit status: #{$?.exitstatus.inspect}\n"
        $?.exitstatus
      end
    end

    def do_fork(programfile, argv)
      $stdout = TerminalOutput.open_for_write
      STDOUT.reopen($stdout)
      STDERR.reopen($stdout)
      $_0 = programfile
      alias $0 $_0

      ARGV.clear
      ARGV.concat argv

      require 'ruby_terminal/reloader'
      RubyTerminal::Reloader.reload_source_files

      if RubyTerminal.options[:rails_test]
        require 'ruby_terminal/rails_project_environment'
        RubyTerminal::RailsProjectEnvironment.reload
      end

      load($0)
    rescue SystemExit, SignalException
      # ignore
    rescue Exception => e
      $stderr.puts e.message
      $stderr.puts e.backtrace.join("\n")
    ensure
      $stdout.close
    end

    def pretty_command(programfile, argv)
      ([programfile] + argv).compact.collect{|c| c.include?(' ') ? c.inspect : c}.join(' ')
    end

  end
end
