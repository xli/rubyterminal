require 'fileutils'

module RubyTerminal
  module Terminal
    def start
      FileUtils.touch '.terminal.running'
      yield if block_given?
    ensure
      FileUtils.rm_rf '.terminal.running'
    end

    def loop_process(logger=[])
      loop do
        process(logger)
        sleep(0.1)
      end
    end

    def process(logger=[])
      return unless File.exists?('.terminal.input')
      begin
        commands = File.open('.terminal.input') do |file|
          file.read
        end.split("\n")

        logger << ">> #{pretty_command(commands)}\n"

        fork { do_fork(commands) }
        Process.wait

        logger << "=> #{$?.exitstatus}\n"
        $?.exitstatus
      ensure
        FileUtils.rm_rf '.terminal.input'
      end
    end

    def do_fork(commands)
      $stdout = File.open('.terminal.output', 'w')
      STDOUT.reopen($stdout)
      STDERR.reopen($stdout)
      ARGV.clear
      $0 = commands[0]
      commands[1..-1].each do |arg|
        ARGV << arg.gsub(/\\n/, "\n")
      end
      load($0)
    rescue Exception => e
      $stderr << e.message
      $stderr << e.backtrace.join("\n")
    ensure
      $stdout.close
    end

    def pretty_command(commands)
      commands.collect{|c| c.include?(' ') ? c.inspect : c}.join(' ')
    end

  end
end
