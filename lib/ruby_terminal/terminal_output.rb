module RubyTerminal
  class TerminalOutput
    FILE_NAME = '.terminal.output'
    def self.full_path
      File.expand_path('.terminal.output')
    end

    def self.renew(&block)
      FileUtils.rm_rf(full_path)
      FileUtils.touch(full_path)

      TerminalOutput.new(File.open(full_path)).open(&block)
    end

    def self.open_for_write
      File.open(full_path, 'w')
    end

    def initialize(file)
      @file = file
    end
    
    def open
      yield(self)
    ensure
      @file.close
    end

    def read
      @file.read
    end

    def path
      @file.path
    end
  end
end