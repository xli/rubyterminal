require 'fileutils'
require 'ruby_terminal/terminal_input'

module RubyTerminal
  module Terminal
    def start
      FileUtils.touch '.terminal.running'
      yield if block_given?
    ensure
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

        fork { do_fork(programfile, argv) }
        Process.wait

        logger << "=> #{$?.exitstatus}\n"
        $?.exitstatus
      end
    end

    def do_fork(programfile, argv)
      $stdout = File.open('.terminal.output', 'w')
      STDOUT.reopen($stdout)
      STDERR.reopen($stdout)
      $0 = programfile
      ARGV.clear
      ARGV.concat argv
      load($0)
    rescue Exception => e
      $stderr.puts e.message
      $stderr.puts e.backtrace.join("\n")
    ensure
      $stdout.close
    end

    def pretty_command(programfile, argv)
      ([programfile] + argv).collect{|c| c.include?(' ') ? c.inspect : c}.join(' ')
    end

  end
end
