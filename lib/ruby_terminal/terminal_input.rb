
module RubyTerminal
  class TerminalInput
    FILE_NAME = '.terminal.input'

    def self.full_path
      File.expand_path(FILE_NAME)
    end

    def self.get
      return unless File.exists?(full_path)
      yield TerminalInput.new(File.open(full_path))
    end

    def self.write(programfile, argv)
      input = TerminalInput.new File.open(full_path, 'w')
      input.write(programfile, argv)
      input
    end

    def initialize(file)
      @file = file
    end

    def write(programfile, argv)
      cmd = [programfile] + argv.collect{|arg| arg.gsub(/\n/, '\\n')}
      @file << cmd.join("\n")
      @file.close
    end

    def read
      commands = @file.read.split("\n").collect {|w| w.gsub(/\\n/, "\n")}
      @file.close
      [commands[0], commands[1..-1]]
    end

    def destroy
      FileUtils.rm_rf path
    end

    def executing?
      File.exists? path
    end

    def path
      @file.path
    end
  end
end
