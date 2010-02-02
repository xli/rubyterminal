
require 'ruby_terminal/terminal'
require 'ruby_terminal/execution'

# for doc, please take a look README
module RubyTerminal
  VERSION = '1.0.0'
  extend Terminal
  extend Execution

  def self.options
    @options ||= {:reload_paths => [], :rails_test => false}
  end
end

RubyTerminal.options[:loaded_at] = Time.now
