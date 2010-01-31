require 'fileutils'

module RubyTerminal
  module Terminal
    def start
      FileUtils.touch '.terminal.running'
      yield if block_given?
    ensure
      FileUtils.rm_rf '.terminal.running'
    end

    def loop_process(&block)
      while(true) do
        process(&block)
        sleep(0.1)
      end
    end

    def process(&block)
      return unless File.exists?('.terminal.input')
      begin
        commands = File.open('.terminal.input') do |file|
          file.read
        end.split("\n")

        puts ">> #{pretty_command(commands)}"

        fork { do_fork(commands, &block) }
        Process.wait

        puts "=> #{$?.exitstatus}"
      ensure
        FileUtils.rm_rf '.terminal.input'
      end
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
    ensure
      $stdout.close
    end

    def pretty_command(commands)
      commands.collect{|c| c.include?(' ') ? c.inspect : c}.join(' ')
    end

  end
end
