
require 'ruby_terminal/terminal'
require 'ruby_terminal/execution'

# for doc, please take a look README
module RubyTerminal
  VERSION = '1.0.0' unless defined?(VERSION)
  extend Terminal
  extend Execution

  def self.options
    @options ||= {:reload_paths => [], :rails_test => false}
  end

  def self.with_reload_paths
    if options[:reload_paths].nil?
      return
    end
    yield(options[:reload_paths].collect { |path| File.expand_path(path) })
  end
end

RubyTerminal.options[:loaded_at] = Time.now
