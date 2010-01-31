$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'ert'
RubyTerminal.ignore_execution_request = false

require 'test/unit'

module DirHelper
  def with_test_dir
    dir = File.join('terminal_test_dir')
    Dir.mkdir(dir)
    Dir.chdir(dir) do
      yield
    end
  ensure
    FileUtils.rm_rf(dir)
  end
end

Test::Unit::TestCase.send(:include, DirHelper)
